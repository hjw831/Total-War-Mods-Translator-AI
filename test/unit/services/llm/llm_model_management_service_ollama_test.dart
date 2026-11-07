import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:twmt/models/common/result.dart';
import 'package:twmt/models/common/service_exception.dart';
import 'package:twmt/models/domain/llm_provider_model.dart';
import 'package:twmt/repositories/llm_provider_model_repository.dart';
import 'package:twmt/services/llm/llm_model_management_service.dart';
import 'package:twmt/services/shared/i_logging_service.dart';

class _MockRepository extends Mock implements LlmProviderModelRepository {}

class _MockLoggingService extends Mock implements ILoggingService {}

LlmProviderModel _model({
  String id = 'existing-model',
  String modelId = 'qwen3.5:9b',
  bool isEnabled = true,
  bool isDefault = true,
}) =>
    LlmProviderModel(
      id: id,
      providerCode: 'ollama',
      modelId: modelId,
      displayName: modelId,
      isEnabled: isEnabled,
      isDefault: isDefault,
      createdAt: 1,
      updatedAt: 1,
      lastFetchedAt: 1,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_model(id: 'fallback', modelId: 'fallback'));
  });

  late _MockRepository repository;
  late _MockLoggingService logging;
  late LlmModelManagementService service;

  setUp(() {
    repository = _MockRepository();
    logging = _MockLoggingService();
    service = LlmModelManagementService(repository, logging);
  });

  test('registers a newly discovered model disabled by default', () async {
    when(() => repository.getByProviderAndModelId('ollama', 'llama3.2:latest'))
        .thenAnswer((_) async =>
            const Ok<LlmProviderModel?, TWMTDatabaseException>(null));
    when(() => repository.insert(any())).thenAnswer((invocation) async =>
        Ok<LlmProviderModel, TWMTDatabaseException>(
          invocation.positionalArguments.single as LlmProviderModel,
        ));

    final result = await service.addModelIfMissing(
      providerCode: 'ollama',
      modelId: 'llama3.2:latest',
    );

    expect(result.isOk, isTrue);
    expect(result.value, isTrue);

    final inserted = verify(() => repository.insert(captureAny()))
        .captured
        .single as LlmProviderModel;
    expect(inserted.providerCode, 'ollama');
    expect(inserted.modelId, 'llama3.2:latest');
    expect(inserted.isEnabled, isFalse);
    expect(inserted.isDefault, isFalse);
    expect(inserted.isArchived, isFalse);
  });

  test('does not overwrite an existing model preference', () async {
    final existing = _model();
    when(() => repository.getByProviderAndModelId('ollama', 'qwen3.5:9b'))
        .thenAnswer((_) async =>
            Ok<LlmProviderModel?, TWMTDatabaseException>(existing));

    final result = await service.addModelIfMissing(
      providerCode: 'ollama',
      modelId: 'qwen3.5:9b',
    );

    expect(result.isOk, isTrue);
    expect(result.value, isFalse);
    verifyNever(() => repository.insert(any()));
  });

  test('rejects empty provider or model identifiers', () async {
    final result = await service.addModelIfMissing(
      providerCode: 'ollama',
      modelId: '  ',
    );

    expect(result.isErr, isTrue);
    expect(result.error.message, contains('required'));
    verifyNever(() => repository.getByProviderAndModelId(any(), any()));
  });
}
