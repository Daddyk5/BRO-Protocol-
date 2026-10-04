import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bro_logo.dart';
import '../../../core/widgets/bro_snackbar.dart';
import '../data/generation.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('HISTORY')),
      body: SafeArea(
        child: items.isEmpty
            ? const _EmptyHistory()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Text(
                      'Your last ${AppConstants.historyLimit} replies, stored only on this phone. Swipe to delete.',
                      style: AppTextStyles.caption,
                    );
                  }
                  final generation = items[index - 1];
                  return _HistoryTile(
                    generation: generation,
                    onDelete: () {
                      ref.read(historyProvider.notifier).delete(generation.id);
                      showBroSnack(context, 'Deleted.');
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Opacity(opacity: 0.5, child: BroLogo(size: 96)),
            const SizedBox(height: 16),
            Text('NO PLAYS YET', style: AppTextStyles.title),
            const SizedBox(height: 6),
            Text(
              'Your generated replies will show up here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.generation, required this.onDelete});

  final Generation generation;
  final VoidCallback onDelete;

  String _ago(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: generation.reply));
    if (context.mounted) showBroSnack(context, 'Copied. Go.');
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(generation.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.85),
          borderRadius: AppRadii.cardRadius,
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.white, semanticLabel: 'Delete'),
      ),
      child: Semantics(
        button: true,
        label: '${generation.mode.title} reply: ${generation.reply}. Tap to copy.',
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Delete'): onDelete,
        },
        excludeSemantics: true,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _copy(context),
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
                          '${generation.mode.title} · ${_ago(generation.createdAt)}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.red),
                        ),
                        const SizedBox(height: 6),
                        Text(generation.reply, style: AppTextStyles.body),
                        const SizedBox(height: 6),
                        Text(
                          generation.context,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.ios_share_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => SharePlus.instance.share(ShareParams(text: generation.reply)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
