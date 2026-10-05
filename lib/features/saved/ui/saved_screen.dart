import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bro_snackbar.dart';
import '../data/saved_reply.dart';
import '../providers/saved_provider.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  Future<void> _copy(BuildContext context, SavedReply reply) async {
    await Clipboard.setData(ClipboardData(text: reply.text));
    if (context.mounted) showBroSnack(context, 'Copied. Go.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SAVED')),
      body: SafeArea(
        child: saved.isEmpty
            ? const _Empty()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: saved.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final reply = saved[i];
                  return Dismissible(
                    key: ValueKey(reply.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => ref.read(savedProvider.notifier).delete(reply.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.85),
                        borderRadius: AppRadii.cardRadius,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.white, semanticLabel: 'Remove'),
                    ),
                    child: Semantics(
                      button: true,
                      label: 'Saved ${reply.mode.title} reply: ${reply.text}. Tap to copy.',
                      customSemanticsActions: {
                        const CustomSemanticsAction(label: 'Remove'): () =>
                            ref.read(savedProvider.notifier).delete(reply.id),
                      },
                      excludeSemantics: true,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _copy(context, reply),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        [reply.mode.title, if (reply.label.isNotEmpty) reply.label].join(' · '),
                                        style: AppTextStyles.caption.copyWith(color: AppColors.red),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(reply.text, style: AppTextStyles.body),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove from saved',
                                  icon: const Icon(Icons.star_rounded, color: AppColors.red),
                                  onPressed: () => ref.read(savedProvider.notifier).delete(reply.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_outline_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('NOTHING SAVED YET', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Tap the star on any reply to keep it here. Saved replies stay until you remove them.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}
