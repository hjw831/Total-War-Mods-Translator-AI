import '../../service_locator.dart';
import '../../shared/i_logging_service.dart';
import '../database_service.dart';
import 'migration_base.dart';

/// Registers Ollama as an optional local LLM provider.
class OllamaProviderMigration extends Migration {
  final ILoggingService _logger;

  OllamaProviderMigration({ILoggingService? logger})
      : _logger = logger ?? ServiceLocator.get<ILoggingService>();

  @override
  String get id => 'ollama_provider';

  @override
  String get description => 'Add local Ollama provider and starter model';

  @override
  int get priority => 270;

  @override
  Future<bool> isApplied() async {
    final result = await DatabaseService.database.rawQuery(
      "SELECT COUNT(*) as cnt FROM translation_providers WHERE code = 'ollama'",
    );
    return (result.first['cnt'] as int) > 0;
  }

  @override
  Future<bool> execute() async {
    try {
      await DatabaseService.execute('''
        INSERT OR IGNORE INTO translation_providers
        (id, code, name, api_endpoint, default_model, max_context_tokens, max_batch_size, rate_limit_rpm, rate_limit_tpm, is_active, created_at)
        VALUES
        ('provider_ollama', 'ollama', 'Ollama (Local)', 'http://127.0.0.1:11434', 'qwen3.5:9b', 32768, 10, 60, 0, 1, strftime('%s', 'now'))
      ''');

      await DatabaseService.execute('''
        INSERT OR IGNORE INTO llm_provider_models
        (id, provider_code, model_id, display_name, is_enabled, is_default, is_archived, created_at, updated_at, last_fetched_at)
        VALUES
        ('model_ollama_qwen35_9b', 'ollama', 'qwen3.5:9b', 'Qwen 3.5 9B (Local)', 1, 0, 0, strftime('%s', 'now'), strftime('%s', 'now'), strftime('%s', 'now'))
      ''');

      _logger.info('Ollama provider and starter model added successfully');
      return true;
    } catch (error, stackTrace) {
      _logger.error('Failed to add Ollama provider', error, stackTrace);
      return false;
    }
  }
}
