import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:twmt/theme/twmt_theme_tokens.dart';
import 'package:twmt/providers/settings_providers.dart';
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
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.plug_connected_24_regular, size: 16),
              label: const Text('Test local connection'),
            ),
            const SizedBox(height: 16),
            const LlmModelsList(providerCode: 'ollama'),
          ],
        ),
      ),
    );
  }
}
