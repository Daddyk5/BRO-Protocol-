import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/bro_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/bro_snackbar.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _steps = [
    (Icons.content_paste_rounded, 'Paste', 'Her bio, her last message, the chat, or your own draft.'),
    (Icons.tune_rounded, 'Pick', 'A mode, who it\'s for, and 3 options or a single tone.'),
    (Icons.copy_rounded, 'Copy & send', 'Choose the reply you like, tweak it if you want, and send it yourself.'),
  ];

  static const _faq = [
    (
      'Does Bro Protocol send messages for me?',
      'Never. It only suggests. You copy the reply and send it yourself, in your own app.'
    ),
    (
      'Is my chat stored anywhere?',
      'History and match notes stay on this device. The text you send for a reply is used to write it and is not '
          'kept on our servers.'
    ),
    (
      'Why am I being asked to wait?',
      'Each device gets a set number of replies per hour to keep the service fast for everyone. Three options '
          'count as three replies. Wait a bit and you\'re back.'
    ),
    (
      'How do match notes help?',
      'Save what you know about her (interests, plans, inside jokes). Pick her under "For" in the composer and '
          'replies can work in one detail, naturally.'
    ),
    (
      'What does "Why it works" mean?',
      'A one-line tip explaining the move behind each reply, so you get better on your own. Turn it off in '
          'Settings → Coaching.'
    ),
    (
      'She said no or stopped replying. Now what?',
      'Respect it. Bro Protocol writes a gracious exit line when someone has clearly said no, and it won\'t help '
          'pressure anyone.'
    ),
    (
      'Can I scan screenshots on the web?',
      'Screenshot scanning works on Android and iOS. On the web, paste the text instead.'
    ),
  ];

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: AppConstants.supportEmail));
    if (context.mounted) showBroSnack(context, 'Email copied: ${AppConstants.supportEmail}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HELP & FAQ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const _Header('HOW IT WORKS'),
            Card(
              child: Column(
                children: [
                  for (final (i, step) in _steps.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surface2,
                        child: Icon(step.$1, size: 20, color: AppColors.text),
                      ),
                      title: Text('${i + 1}. ${step.$2}', style: AppTextStyles.label),
                      subtitle: Text(step.$3, style: AppTextStyles.caption),
                    ),
                  ],
                ],
              ),
            ),
            const _Header('THE PLAYS'),
            Card(
              child: Column(
                children: [
                  for (final (i, mode) in BroMode.values.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: Icon(mode.icon, color: AppColors.textMuted),
                      title: Text(mode.title, style: AppTextStyles.label),
                      subtitle: Text(mode.description, style: AppTextStyles.caption),
                    ),
                  ],
                ],
              ),
            ),
            const _Header('FAQ'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, item) in _faq.indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(item.$1, style: AppTextStyles.label),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedAlignment: Alignment.centerLeft,
                      children: [Text(item.$2, style: AppTextStyles.bodyMuted)],
                    ),
                  ],
                ],
              ),
            ),
            const _Header('STILL STUCK?'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: const Text('Contact support'),
                subtitle: const Text(AppConstants.supportEmail),
                trailing: const Icon(Icons.copy_rounded, size: 18),
                onTap: () => _copyEmail(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Semantics(header: true, child: Text(text, style: AppTextStyles.title.copyWith(fontSize: 18))),
    );
  }
}
