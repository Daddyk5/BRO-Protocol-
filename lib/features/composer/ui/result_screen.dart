import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/bro_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bro_snackbar.dart';
import '../../../core/widgets/fist_bump_loader.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../history/data/generation.dart';
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

class _ResultView extends StatefulWidget {
  const _ResultView({super.key, required this.generation, required this.onRegenerate});

  final Generation generation;
  final VoidCallback onRegenerate;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  late final List<ReplyOption> _options = widget.generation.allOptions;

  // Start on the main (Balanced) reply.
  late int _selected = () {
    final i = _options.indexWhere((o) => o.text == widget.generation.reply);
    return i < 0 ? 0 : i;
  }();

  String get _reply => _options[_selected].text;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _reply));
    if (context.mounted) showBroSnack(context, 'Copied. Go.');
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: _reply,
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final generation = widget.generation;
    final isOpener = generation.mode == BroMode.opener;
    final multiple = _options.length > 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          multiple
              ? '${generation.mode.title} · ${_options.length} options · ${generation.language.label}'
              : '${generation.mode.title} · ${toneLabel(generation.tone)} · ${generation.language.label}',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 16),
        _Bubble.received(
          label: isOpener ? 'Her profile' : 'Her',
          text: generation.context,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          if (multiple)
            _Bubble.option(
              label: _options[i].label,
              text: _options[i].text,
              selected: i == _selected,
              onTap: () => setState(() => _selected = i),
            )
          else
            _Bubble.sent(text: _options[i].text),
        ],
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            multiple ? 'Tap one to pick it. Nothing is sent for you.' : 'Not sent. Copy it and send it yourself.',
            style: AppTextStyles.caption,
          ),
        ),
        const SizedBox(height: 32),
        GradientButton(
          label: multiple ? 'COPY ${_options[_selected].label.toUpperCase()}' : 'COPY',
          icon: Icons.copy_rounded,
          semanticsLabel: 'Copy reply',
          onPressed: () => _copy(context),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onRegenerate,
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
