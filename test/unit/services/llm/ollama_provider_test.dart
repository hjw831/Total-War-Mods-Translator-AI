import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:twmt/services/llm/models/llm_request.dart';
import 'package:twmt/services/llm/providers/ollama_provider.dart';

import '../../../helpers/fakes/fake_token_calculator.dart';

class _MockDio extends Mock implements Dio {}

LlmRequest _request() => LlmRequest(
      requestId: 'ollama-test',
      targetLanguage: 'Korean',
      texts: const {'unit_name': 'Spearmen', 'unit_desc': 'A sturdy infantry unit.'},
      systemPrompt: 'Translate Total War game strings.',
      modelName: 'qwen3.5:9b',
      maxTokens: 512,
      timestamp: DateTime(2026, 11, 7),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/api/chat'));
    registerFallbackValue(CancelToken());
  });

  test('sends a keyless non-streaming JSON chat request and parses translations', () async {
    final dio = _MockDio();
    final provider = OllamaProvider(
      dio: dio,
      tokenCalculator: FakeTokenCalculator(),
    );
    final body = <String, dynamic>{
      'model': 'qwen3.5:9b',
      'message': {
        'role': 'assistant',
        'content': jsonEncode({
          'unit_name': '창병',
          'unit_desc': '튼튼한 보병 부대입니다.',
        }),
      },
      'prompt_eval_count': 40,
      'eval_count': 12,
      'done': true,
    };

    when(() => dio.post(
          any(),
          data: any(named: 'data'),
          cancelToken: any(named: 'cancelToken'),
        )).thenAnswer((_) async => Response<dynamic>(
          data: body,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/chat'),
        ));

    final result = await provider.translate(_request(), '');

    expect(result.isOk, isTrue, reason: 'Expected Ok but got $result');
    expect(result.value.translations, {
      'unit_name': '창병',
      'unit_desc': '튼튼한 보병 부대입니다.',
    });
    expect(result.value.providerCode, 'ollama');
    expect(result.value.inputTokens, 40);
    expect(result.value.outputTokens, 12);

    final captured = verify(() => dio.post(
          captureAny(),
          data: captureAny(named: 'data'),
          cancelToken: any(named: 'cancelToken'),
        )).captured;
    expect(captured[0], '/api/chat');
    final payload = captured[1] as Map<String, dynamic>;
    expect(payload['model'], 'qwen3.5:9b');
    expect(payload['stream'], isFalse);
    expect(payload['format'], 'json');
    expect((payload['options'] as Map)['num_predict'], 512);
  });

  test('does not report streaming support', () {
    final provider = OllamaProvider(
      dio: _MockDio(),
      tokenCalculator: FakeTokenCalculator(),
    );
    expect(provider.supportsStreaming, isFalse);
  });

  test('validates the local model list without an API key', () async {
    final dio = _MockDio();
    final provider = OllamaProvider(
      dio: dio,
      tokenCalculator: FakeTokenCalculator(),
    );
    when(() => dio.get(any())).thenAnswer((_) async => Response<dynamic>(
          data: {
            'models': [
              {'name': 'qwen3.5:9b', 'model': 'qwen3.5:9b'},
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/tags'),
        ));

    final result = await provider.validateApiKey('', model: 'qwen3.5:9b');
    expect(result.isOk, isTrue);
  });
}
