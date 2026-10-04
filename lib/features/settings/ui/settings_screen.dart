import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/bro_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/bro_logo.dart';
import '../../../core/widgets/bro_snackbar.dart';
import '../../history/providers/history_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double? _draftTone;

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CLEAR HISTORY?'),
        content: const Text('This deletes every saved reply on this phone. It can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(historyProvider.notifier).clear();
    if (mounted) showBroSnack(context, 'History cleared.');
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.version,
      applicationIcon: const BroLogo(size: 56),
      applicationLegalese: '© 2026 Bro Protocol',
      children: [
        const SizedBox(height: 16),
        Text(AppConstants.tagline, style: AppTextStyles.title),
        const SizedBox(height: 8),
        Text(
          'An AI wingman that writes one confident, respectful reply at a time. '
          'Bro Protocol never sends anything for you: you copy, you paste, you hit send. '
          'Screenshots are read on-device; history stays on this phone.',
          style: AppTextStyles.bodyMuted,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final tone = _draftTone ?? settings.defaultTone;

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            const _SectionHeader('DEFAULT TONE'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('Starts every new draft at', style: AppTextStyles.bodyMuted),
                          const Spacer(),
                          Text(toneLabel(tone), style: AppTextStyles.label.copyWith(color: AppColors.red)),
                        ],
                      ),
                    ),
                    Slider(
                      value: tone,
                      onChanged: (v) => setState(() => _draftTone = v),
                      onChangeEnd: (v) {
                        notifier.setDefaultTone(v);
                        setState(() => _draftTone = null);
                      },
                      semanticFormatterCallback: (v) => 'Default tone ${toneLabel(v)}',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Chill', style: AppTextStyles.caption),
                          Text('Bold', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _SectionHeader('LANGUAGE'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AppLanguage>(
                segments: [
                  for (final language in AppLanguage.values)
                    ButtonSegment(value: language, label: Text(language.label)),
                ],
                selected: {settings.language},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => notifier.setLanguage(selection.first),
              ),
            ),
            const _SectionHeader('DATA'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Clear history'),
                subtitle: const Text('Remove all saved replies from this phone'),
                onTap: _confirmClear,
              ),
            ),
            const _SectionHeader('ABOUT'),
            Card(
              child: ListTile(
                leading: const BroLogo(size: 32),
                title: const Text('About Bro Protocol'),
                subtitle: Text('Version ${AppConstants.version}'),
                onTap: _showAbout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Semantics(header: true, child: Text(text, style: AppTextStyles.title.copyWith(fontSize: 18))),
    );
  }
}
