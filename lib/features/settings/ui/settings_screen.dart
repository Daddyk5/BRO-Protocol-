import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/bro_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/bro_logo.dart';
import '../../../core/widgets/bro_snackbar.dart';
import '../../composer/providers/composer_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../legal/legal_text.dart';
import '../../matches/providers/matches_provider.dart';
import '../../saved/providers/saved_provider.dart';
import '../../stats/providers/stats_provider.dart';
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

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DELETE ALL MY DATA?'),
        content: const Text(
          'This erases your history, saved replies, match notes, stats and settings from this device and resets '
          'your install ID. '
          'It can\'t be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(historyProvider.notifier).clear();
    await ref.read(matchesProvider.notifier).clear();
    await ref.read(savedProvider.notifier).clear();
    await ref.read(statsProvider.notifier).clear();
    await ref.read(settingsProvider.notifier).reset();
    ref.invalidate(composerProvider);
    if (!mounted) return;
    showBroSnack(context, 'All your data was deleted.');
    context.go('/onboarding');
  }

  Future<void> _editStyle(String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('YOUR TEXTING STYLE'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: AppConstants.maxStyleLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Dry humour, mostly lowercase, no exclamation marks.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (result != null) await ref.read(settingsProvider.notifier).setStyleNotes(result);
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
            const _SectionHeader('YOUR STYLE'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_note_rounded),
                    title: const Text('How you text'),
                    subtitle: Text(
                      settings.styleNotes.isEmpty ? 'Not set. Replies use a neutral style.' : settings.styleNotes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _editStyle(settings.styleNotes),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.emoji_emotions_outlined),
                    title: const Text('Allow emoji'),
                    subtitle: const Text('Off removes every emoji from replies'),
                    value: settings.allowEmoji,
                    onChanged: notifier.setAllowEmoji,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.short_text_rounded),
                    title: const Text('Short replies'),
                    subtitle: const Text('One sentence instead of up to two'),
                    value: settings.shortReplies,
                    onChanged: notifier.setShortReplies,
                  ),
                ],
              ),
            ),
            const _SectionHeader('COACHING'),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.lightbulb_outline_rounded),
                title: const Text('Show why it works'),
                subtitle: const Text('A one-line tip under each reply'),
                value: settings.showTips,
                onChanged: notifier.setShowTips,
              ),
            ),
            const _SectionHeader('FEEL'),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.vibration_rounded),
                title: const Text('Haptic feedback'),
                subtitle: const Text('A light tap when you generate or copy (phones)'),
                value: settings.haptics,
                onChanged: notifier.setHaptics,
              ),
            ),
            const _SectionHeader('HELP & LEGAL'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded),
                    title: const Text('Help & FAQ'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/home/help'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/legal/${LegalDoc.privacy.name}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.gavel_rounded),
                    title: const Text('Terms of Use'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/legal/${LegalDoc.terms.name}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.replay_rounded),
                    title: const Text('Replay the intro'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/onboarding'),
                  ),
                ],
              ),
            ),
            const _SectionHeader('DATA'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined),
                    title: const Text('Clear history'),
                    subtitle: const Text('Remove all saved replies from this device'),
                    onTap: _confirmClear,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: AppColors.red),
                    title: Text('Delete all my data', style: AppTextStyles.body.copyWith(color: AppColors.red)),
                    subtitle: const Text('History, saved, matches, stats, settings and install ID'),
                    onTap: _confirmDeleteAll,
                  ),
                ],
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
            const SizedBox(height: 24),
            Text(
              'Made for confident, respectful conversations.\nNothing is ever sent for you.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
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
