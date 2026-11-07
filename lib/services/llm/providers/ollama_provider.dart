import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:twmt/models/common/result.dart';
import 'package:twmt/services/llm/providers/i_llm_provider.dart';
import 'package:twmt/services/llm/models/llm_request.dart';
import 'package:twmt/services/llm/models/llm_response.dart';
import 'package:twmt/services/llm/models/llm_provider_config.dart';
import 'package:twmt/services/llm/models/llm_exceptions.dart';
import 'package:twmt/services/llm/utils/token_calculator.dart';

/// Local Ollama provider using the native /api/chat endpoint.
///
/// The first implementation deliberately uses non-streaming requests only.
/// Ollama is expected to be running locally; no API key is required.
class OllamaProvider implements ILlmProvider {
  static const String defaultBaseUrl = 'http://127.0.0.1:11434';

  final Dio _dio;
  final TokenCalculator _tokenCalculator;

  @override
  final String providerCode = 'ollama';

  @override
  final String providerName = 'Ollama (Local)';

  @override
  final LlmProviderConfig config = LlmProviderConfig(
    providerCode: 'ollama',
    providerName: 'Ollama (Local)',
    apiBaseUrl: defaultBaseUrl,
    supportsStreaming: false,
    maxTokensPerRequest: 32768,
    defaultRateLimitRpm: 60,
    retryConfig: RetryConfig.defaultConfig,
  );

  OllamaProvider({Dio? dio, TokenCalculator? tokenCalculator})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: defaultBaseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(minutes: 5),
              headers: {'Content-Type': 'application/json'},
            )),
        _tokenCalculator = tokenCalculator ?? TokenCalculator();

  @override
  Future<Result<LlmResponse, LlmProviderException>> translate(
    LlmRequest request,
    String apiKey, {
    CancelToken? cancelToken,
  }) async {
    final startedAt = DateTime.now();
    final model = request.modelName?.trim() ?? '';
    if (model.isEmpty) {
      return Err(LlmInvalidRequestException(
        'Select an Ollama model before translating.',
        providerCode: providerCode,
      ));
    }

    try {
      final response = await _dio.post(
        '/api/chat',
        data: {
          'model': model,
          'stream': false,
          'format': 'json',
          'messages': [
            {'role': 'system', 'content': _buildSystemPrompt(request)},
            ..._fewShotMessages(request),
            {'role': 'user', 'content': _buildUserMessage(request)},
          ],
          'options': {
            'num_predict': request.maxTokens ?? 4096,
          },
        },
        cancelToken: cancelToken,
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final message = data['message'];
      final content = message is Map ? message['content'] as String? : null;
      if (content == null || content.trim().isEmpty) {
        throw LlmResponseParseException(
          'Ollama returned an empty message.',
          providerCode: providerCode,
          rawResponse: data.toString(),
        );
      }

      final translations = _parseTranslations(content, request);
      final inputTokens = data['prompt_eval_count'] as int? ?? 0;
      final outputTokens = data['eval_count'] as int? ?? 0;

      return Ok(LlmResponse(
        requestId: request.requestId,
        translations: translations,
        providerCode: providerCode,
        modelName: data['model'] as String? ?? model,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        totalTokens: inputTokens + outputTokens,
        processingTimeMs: DateTime.now().difference(startedAt).inMilliseconds,
        timestamp: DateTime.now(),
        finishReason: data['done'] == true ? 'completed' : 'unknown',
      ));
    } on DioException catch (error) {
      return Err(_handleDioException(error));
    } on LlmProviderException catch (error) {
      return Err(error);
    } catch (error, stackTrace) {
      return Err(LlmProviderException(
        'Failed to parse Ollama response: $error',
        providerCode: providerCode,
        code: 'RESPONSE_PARSE_ERROR',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  int estimateTokens(String text) => _tokenCalculator.calculateTokens(text);

  @override
  int estimateRequestTokens(LlmRequest request) =>
      _tokenCalculator.estimateRequestTokens(request);

  /// Returns the model tags currently installed in the local Ollama server.
  ///
  /// The returned names are suitable for use as `LlmRequest.modelName`.
  Future<Result<List<String>, LlmProviderException>> getInstalledModels() async {
    try {
      final response = await _dio.get('/api/tags');
      final data = response.data;
      if (data is! Map || data['models'] is! List) {
        return Err(LlmNetworkException(
          'Ollama responded, but its model list was invalid.',
          providerCode: providerCode,
        ));
      }

      final names = <String>{};
      for (final entry in data['models'] as List) {
        if (entry is! Map) continue;
        final name = entry['name'] ?? entry['model'];
        if (name is String && name.trim().isNotEmpty) {
          names.add(name.trim());
        }
      }

      final sortedNames = names.toList()..sort();
      return Ok(sortedNames);
    } on DioException catch (error) {
      return Err(_handleDioException(error));
    } catch (error, stackTrace) {
      return Err(LlmProviderException(
        'Could not retrieve installed Ollama models: $error',
        providerCode: providerCode,
        code: 'MODEL_LIST_ERROR',
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<bool, LlmProviderException>> validateApiKey(
    String apiKey, {
    String? model,
  }) async {
    final result = await getInstalledModels();
    if (result.isErr) return Err(result.error);

    if (model != null &&
        model.trim().isNotEmpty &&
        !result.value.contains(model.trim())) {
      return Err(LlmInvalidRequestException(
        'Model "$model" is not installed in Ollama. Pull it with "ollama pull $model".',
        providerCode: providerCode,
        code: 'MODEL_NOT_FOUND',
      ));
    }

    return const Ok(true);
  }

  @override
  bool get supportsStreaming => false;

  @override
  Stream<Result<String, LlmProviderException>> translateStreaming(
    LlmRequest request,
    String apiKey,
  ) async* {
    yield Err(LlmProviderException(
      'Ollama streaming is not enabled in this version.',
      providerCode: providerCode,
      code: 'STREAMING_NOT_SUPPORTED',
    ));
  }

  @override
  Duration calculateRetryDelay(LlmRateLimitException exception) =>
      const Duration(seconds: 2);

  @override
  Future<Result<bool, LlmProviderException>> isAvailable() async {
    final result = await getInstalledModels();
    return result.when(
      ok: (_) => const Ok(true),
      err: (error) => Err(error),
    );
  }

  @override
  Future<Result<RateLimitStatus?, LlmProviderException>> getRateLimitStatus(
    String apiKey,
  ) async => const Ok(null);

  List<Map<String, String>> _fewShotMessages(LlmRequest request) {
    final examples = request.fewShotExamples;
    if (examples == null || examples.isEmpty) return [];

    final messages = <Map<String, String>>[];
    for (final example in examples) {
      messages.add({'role': 'user', 'content': 'Translate: ${example.source}'});
      messages.add({
        'role': 'assistant',
        'content': jsonEncode({example.source: example.target}),
      });
    }
    return messages;
  }

  String _buildSystemPrompt(LlmRequest request) {
    final parts = <String>[request.systemPrompt];
    if (request.gameContext != null) {
      parts.add('\n\n## Game Context\n${request.gameContext}');
    }
    if (request.projectContext != null) {
      parts.add('\n\n## Project Context\n${request.projectContext}');
    }
    if (request.glossaryTerms?.isNotEmpty == true) {
      parts.add('\n\n## Glossary Terms\n${request.glossaryTerms!.entries.map((e) => '- "${e.key}" → "${e.value}" (preserve exactly)').join('\n')}');
    }
    parts.add(
      '\n\nCRITICAL: Preserve every game tag, formatting token, and placeholder exactly, '
      'including [[col:red]], [%s], <tags>, and {{...}} expressions. '
      'Do not translate object keys. Return valid JSON only, with exactly the same keys '
      'as the input object and translated string values.',
    );
    return parts.join();
  }

  String _buildUserMessage(LlmRequest request) =>
      'Translate the following text to ${request.targetLanguage}. '
      'Preserve all tags and placeholders exactly. Return only a JSON object '
      'with the same keys:\n${jsonEncode(request.texts)}';

  Map<String, String> _parseTranslations(String content, LlmRequest request) {
    var jsonText = content.trim();
    if (jsonText.startsWith('```')) {
      final firstLine = jsonText.indexOf('\n');
      if (firstLine >= 0) jsonText = jsonText.substring(firstLine + 1);
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3).trim();
      }
    }

    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) {
      throw FormatException('Ollama response must be a JSON object.');
    }

    final result = <String, String>{};
    final values = decoded['translations'];

    if (values is List) {
      for (final item in values) {
        if (item is Map) {
          final key = item['key'];
          final value = item['translation'];
          if (key is String && value is String && request.texts.containsKey(key)) {
            result[key] = value;
          }
        }
      }
    } else {
      // Accept both a direct {key: translation} object and a wrapped
      // {"translations": {key: translation}} object.
      final translationMap = values is Map ? values : decoded;
      for (final entry in translationMap.entries) {
        if (entry.key is String &&
            entry.value is String &&
            request.texts.containsKey(entry.key)) {
          result[entry.key as String] = entry.value as String;
        }
      }
    }

    // A partial response must never be reported as a successful batch:
    // downstream code treats every returned translation as completed.
    final missingKeys = request.texts.keys
        .where((key) => !result.containsKey(key))
        .toList(growable: false);
    if (missingKeys.isNotEmpty) {
      throw LlmResponseParseException(
        'Ollama response is missing ${missingKeys.length} translation key(s): ${missingKeys.join(', ')}',
        providerCode: providerCode,
        rawResponse: content,
        details: {'missingKeys': missingKeys},
      );
    }
    return result;
  }

  LlmProviderException _handleDioException(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return LlmCancelledException(
        'Ollama translation was cancelled.',
        providerCode: providerCode,
      );
    }
    if (error.response?.statusCode == 404) {
      return LlmInvalidRequestException(
        'Ollama endpoint or model was not found. Check that Ollama is running and the model is installed.',
        providerCode: providerCode,
        code: 'OLLAMA_NOT_FOUND',
      );
    }
    if (error.response?.statusCode != null &&
        error.response!.statusCode! >= 500) {
      return LlmServerException(
        'Ollama server error: ${error.message ?? error.response?.statusCode}',
        providerCode: providerCode,
        statusCode: error.response!.statusCode!,
      );
    }
    return LlmNetworkException(
      'Cannot reach Ollama at $defaultBaseUrl. Start Ollama and try again. '
      'Details: ${error.message ?? error.type.name}',
      providerCode: providerCode,
      details: {'statusCode': error.response?.statusCode},
    );
  }
}
