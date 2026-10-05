import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/bro_mode.dart';
import '../../../core/constants/reply_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bro_snackbar.dart';
import '../../../core/widgets/fist_bump_loader.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../services/api_service.dart';
import '../../history/data/generation.dart';
import '../../saved/providers/saved_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/generation_provider.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(generationProvider);
    final controller = ref.read(generationProvider.notifier);

    final Widget body = switch (result) {
      AsyncData(value: final Generation generation) => _ResultView(
          key: ValueKey(generation.id),
          generation: generation,
          onRegenerate: controller.regenerate,
        ),
      AsyncError(:final error) => _ErrorView(
          message: error.toString(),
          onRetry: controller.lastRequest == null ? null : controller.regenerate,
        ),
      AsyncLoading() => const _LoadingView(),
      _ => const _ErrorView(message: 'Nothing generated yet. Head back and hit GENERATE.'),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('YOUR REPLY')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.slow),
          switchInCurve: AppMotion.curve,
          switchOutCurve: AppMotion.curve,
          child: body,
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FistBumpLoader(size: 140),
          const SizedBox(height: 16),
          Text('Reading the room…', style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_mma_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultView extends ConsumerStatefulWidget {
  const _ResultView({super.key, required this.generation, required this.onRegenerate});

  final Generation generation;
  final VoidCallback onRegenerate;

  @override
  ConsumerState<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends ConsumerState<_ResultView> {
  // Null until the user picks one: start on the main (Balanced) reply.
  int? _picked;
  ReplyTweak? _busy;

  List<ReplyOption> get _options => widget.generation.allOptions;

  int get _selected {
    final i = _picked ?? _options.indexWhere((o) => o.text == widget.generation.reply);
    return i < 0 ? 0 : i.clamp(0, _options.length - 1);
  }

  ReplyOption get _option => _options[_selected];

  void _haptic() {
    if (ref.read(settingsProvider).haptics) HapticFeedback.lightImpact();
  }

  Future<void> _copy(BuildContext context) async {
    _haptic();
    await Clipboard.setData(ClipboardData(text: _option.text));
    if (context.mounted) showBroSnack(context, 'Copied. Go.');
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: _option.text,
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _tweak(ReplyTweak tweak) async {
    setState(() => _busy = tweak);
    try {
      await ref.read(generationProvider.notifier).tweak(_selected, tweak);
      _haptic();
    } on ApiException catch (e) {
      if (mounted) showBroSnack(context, e.message);
    } catch (_) {
      if (mounted) showBroSnack(context, 'Couldn\'t rework that one. Try again.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _edit() async {
    final index = _selected;
    final edited = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EditSheet(initial: _options[index].text),
    );
    if (edited == null || edited.trim().isEmpty || edited.trim() == _options[index].text) return;
    await ref.read(generationProvider.notifier).replaceOption(index, _options[index].withText(edited.trim()));
  }

  Future<void> _toggleSaved() async {
    final saved = await ref
        .read(savedProvider.notifier)
        .toggle(text: _option.text, mode: widget.generation.mode, label: _option.label);
    _haptic();
    if (mounted) showBroSnack(context, saved ? 'Saved. Find it under Saved on Home.' : 'Removed from Saved.');
  }

  @override
  Widget build(BuildContext context) {
    final generation = widget.generation;
    final options = _options;
    final isOpener = generation.mode == BroMode.opener;
    final multiple = options.length > 1;
    final isSaved = ref.watch(savedProvider).any((s) => s.text == _option.text);
    final busy = _busy != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          multiple
              ? '${generation.mode.title} · ${options.length} options · ${generation.language.label}'
              : '${generation.mode.title} · ${options.first.label} · ${generation.language.label}',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 16),
        _Bubble.received(
          label: isOpener ? 'Her profile' : 'Her',
          text: generation.context,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          AnimatedOpacity(
            duration: AppMotion.of(context, AppMotion.fast),
            opacity: busy && i == _selected ? 0.5 : 1,
            child: multiple
                ? _Bubble.option(
                    label: options[i].label,
                    text: options[i].text,
                    selected: i == _selected,
                    onTap: busy ? null : () => setState(() => _picked = i),
                  )
                : _Bubble.sent(text: options[i].text),
          ),
        ],
        if (_option.tip case final tip?) ...[
          const SizedBox(height: 12),
          _TipCard(tip: tip),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: busy ? null : _edit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
            TextButton.icon(
              onPressed: _toggleSaved,
              icon: Icon(isSaved ? Icons.star_rounded : Icons.star_outline_rounded, size: 18),
              label: Text(isSaved ? 'Saved' : 'Save'),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                multiple ? 'Tap one to pick it.' : 'Not sent for you.',
                textAlign: TextAlign.right,
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('REWORK ${multiple ? _option.label.toUpperCase() : 'IT'}', style: AppTextStyles.title.copyWith(fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tweak in ReplyTweak.values)
              ActionChip(
                avatar: _busy == tweak
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(tweak.icon, size: 16),
                label: Text(tweak.label),
                onPressed: busy ? null : () => _tweak(tweak),
                tooltip: '${tweak.label}: rewrite this reply',
              ),
          ],
        ),
        const SizedBox(height: 28),
        GradientButton(
          label: multiple ? 'COPY ${_option.label.toUpperCase()}' : 'COPY',
          icon: Icons.copy_rounded,
          semanticsLabel: 'Copy reply',
          onPressed: busy ? null : () => _copy(context),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : widget.onRegenerate,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Regenerate'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (buttonContext) => OutlinedButton.icon(
                  onPressed: () => _share(buttonContext),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.initial});

  final String initial;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('EDIT REPLY', style: AppTextStyles.headline),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 2,
            maxLines: 6,
            maxLength: 600,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context, _text.text),
            style: FilledButton.styleFrom(shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius)),
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Done')),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Why it works: $tip',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Why it works: ', style: AppTextStyles.label),
                    TextSpan(text: tip, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble.received({required this.label, required this.text})
      : sent = false,
        selected = false,
        onTap = null;

  const _Bubble.sent({required this.text})
      : sent = true,
        selected = true,
        label = 'You',
        onTap = null;

  /// One of several options: full gradient when [selected], outlined otherwise.
  const _Bubble.option({required this.label, required this.text, required this.selected, required this.onTap})
      : sent = true;

  final bool sent;
  final String label;
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(20);
    final borderRadius = BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: sent ? radius : const Radius.circular(6),
      bottomRight: sent ? const Radius.circular(6) : radius,
    );

    final highlighted = sent && selected;
    return Semantics(
      label: !sent
          ? '$label: $text'
          : onTap == null
              ? 'Your reply: $text'
              : '$label option${selected ? ', selected' : ''}: $text',
      button: onTap != null,
      selected: onTap != null && selected,
      excludeSemantics: true,
      onTap: onTap,
      child: Align(
        alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
          child: Column(
            crossAxisAlignment: sent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(label, style: AppTextStyles.caption),
              ),
              GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.fast),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: highlighted ? AppColors.gradient : null,
                    color: highlighted ? null : AppColors.surface2,
                    border: sent && !highlighted ? Border.all(color: AppColors.border) : null,
                    borderRadius: borderRadius,
                    boxShadow: highlighted ? AppColors.gradientGlow : null,
                  ),
                  child: sent
                      ? (onTap == null
                          ? SelectableText(text, style: AppTextStyles.bubble)
                          : Text(text, style: highlighted ? AppTextStyles.bubble : AppTextStyles.body))
                      : Text(
                          text,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
