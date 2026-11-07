import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:twmt/theme/twmt_theme_tokens.dart';
import 'package:twmt/providers/settings_providers.dart';
import 'package:twmt/providers/shared/service_providers.dart' as bridge;
import 'package:twmt/services/llm/providers/ollama_provider.dart';
import 'package:twmt/widgets/settings/settings_accordion_section.dart';
import 'package:twmt/widgets/fluent/fluent_widgets.dart';
import 'llm_models_list.dart';

/// Ollama settings are intentionally keyless: the local server is discovered
/// at the default loopback address and model management remains DB-backed.
class OllamaProviderSection extends ConsumerStatefulWidget {
  const OllamaProviderSection({super.key});

  @override
  ConsumerState<OllamaProviderSection> createState() =>
      _OllamaProviderSectionState();
}

class _OllamaProviderSectionState extends ConsumerState<OllamaProviderSection> {
  bool _isTesting = false;
  bool _isSyncingModels = false;

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    try {
      final (success, error) = await ref
          .read(llmProviderSettingsProvider.notifier)
          .testConnection('ollama');
      if (!mounted) return;
      if (success) {
        FluentToast.success(context, 'Ollama connection successful.');
      } else {
        FluentToast.error(context, error ?? 'Could not connect to Ollama.');
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _syncInstalledModels() async {
    setState(() => _isSyncingModels = true);
    try {
      final provider = ref
          .read(bridge.llmProviderFactoryProvider)
          .getProvider('ollama');
      if (provider is! OllamaProvider) {
        throw StateError('The Ollama provider is not registered.');
      }

      final modelsResult = await provider.getInstalledModels();
      if (modelsResult.isErr) {
        throw Exception(modelsResult.error.message);
      }

      final installedModels = modelsResult.value;
      if (installedModels.isEmpty) {
        if (mounted) {
          FluentToast.error(
            context,
            'No installed Ollama models were found. Run "ollama pull <model>".',
          );
        }
        return;
      }

      final modelService = ref.read(llmModelManagementServiceProvider);
      var addedCount = 0;
      for (final modelId in installedModels) {
        final result = await modelService.addModelIfMissing(
          providerCode: 'ollama',
          modelId: modelId,
        );
        if (result.isErr) {
          throw Exception(result.error.message);
        }
        if (result.value) addedCount++;
      }

      ref.invalidate(llmModelsProvider('ollama'));
      if (mounted) {
        FluentToast.success(
          context,
          'Found ${installedModels.length} installed model(s); added ${addedCount} new model(s). Enable a model below to use it.',
        );
      }
    } catch (error) {
      if (mounted) {
        FluentToast.error(context, 'Could not sync Ollama models: $error');
      }
    } finally {
      if (mounted) setState(() => _isSyncingModels = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SettingsAccordionSection(
        icon: FluentIcons.desktop_24_regular,
        title: 'Ollama (Local)',
        subtitle: 'Run translations on your own computer. No API key required.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server: http://127.0.0.1:11434',
              style: tokens.fontBody.copyWith(fontSize: 13, color: tokens.textDim),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure Ollama is running and the model is installed. '
              'The starter model is qwen3.5:9b; you can enable it below.',
              style: tokens.fontBody.copyWith(fontSize: 12, color: tokens.textDim),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: (_isTesting || _isSyncingModels) ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(FluentIcons.plug_connected_24_regular, size: 16),
                  label: const Text('Test local connection'),
                ),
                OutlinedButton.icon(
                  onPressed: (_isTesting || _isSyncingModels)
                      ? null
                      : _syncInstalledModels,
                  icon: _isSyncingModels
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(FluentIcons.arrow_sync_24_regular, size: 16),
                  label: const Text('Sync installed models'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const LlmModelsList(providerCode: 'ollama'),
          ],
        ),
      ),
    );
  }
}
