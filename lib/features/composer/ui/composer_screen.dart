import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/bro_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/bro_snackbar.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../services/ocr_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../data/reply_repository.dart';
import '../providers/composer_provider.dart';
import '../providers/generation_provider.dart';

class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({super.key});

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  late final TextEditingController _text = TextEditingController(text: ref.read(composerProvider).text);
  bool _scanning = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      final text = await ref.read(ocrServiceProvider).pickAndRecognize();
      if (!mounted || text == null) return;
      if (text.isEmpty) {
        showBroSnack(context, 'No text found in that screenshot.');
        return;
      }
      ref.read(composerProvider.notifier).appendText(text);
    } on PlatformException catch (e) {
      if (mounted) showBroSnack(context, e.code == 'photo_access_denied' ? 'Photo access is off.' : 'Couldn\'t open your photos.');
    } catch (_) {
      if (mounted) showBroSnack(context, 'Couldn\'t read that screenshot.');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _generate() {
    final state = ref.read(composerProvider);
    if (!state.canGenerate) return;
    FocusScope.of(context).unfocus();
    ref.read(generationProvider.notifier).generate(
          ReplyRequest(
            mode: state.mode,
            context: state.text.trim(),
            tone: state.tone,
            language: ref.read(settingsProvider).language,
          ),
        );
    context.push('/home/composer/result');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(composerProvider);
    final controller = ref.read(composerProvider.notifier);

    // Keep the field in sync when text arrives from OCR or the share sheet.
    ref.listen<ComposerState>(composerProvider, (_, next) {
      if (next.text != _text.text) {
        _text.value = TextEditingValue(
          text: next.text,
          selection: TextSelection.collapsed(offset: next.text.length),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('COMPOSER')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _ModeChips(selected: state.mode, onSelected: controller.setMode),
            const SizedBox(height: 20),
            Text(state.mode.inputLabel.toUpperCase(), style: AppTextStyles.title.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Semantics(
              label: 'Conversation context',
              textField: true,
              child: TextField(
                controller: _text,
                onChanged: controller.setText,
                minLines: 6,
                maxLines: 12,
                maxLength: AppConstants.maxContextLength,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Paste her bio / her message / the chat here',
                  counterStyle: AppTextStyles.caption,
                  suffixIcon: state.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                          onPressed: () => controller.setText(''),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _scanning ? null : _scan,
                icon: _scanning
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.document_scanner_outlined, size: 20),
                label: Text(_scanning ? 'Reading…' : 'Scan screenshot'),
              ),
            ),
            const SizedBox(height: 24),
            _ToneSlider(value: state.tone, onChanged: controller.setTone),
            const SizedBox(height: 28),
            GradientButton(
              label: 'GENERATE',
              icon: Icons.bolt_rounded,
              semanticsLabel: 'Generate reply',
              onPressed: state.canGenerate ? _generate : null,
            ),
            const SizedBox(height: 12),
            Text(
              'You stay in control: nothing is ever sent for you.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChips extends StatelessWidget {
  const _ModeChips({required this.selected, required this.onSelected});

  final BroMode selected;
  final ValueChanged<BroMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in BroMode.values)
          Semantics(
            selected: mode == selected,
            child: ChoiceChip(
              label: Text(mode.title),
              avatar: Icon(mode.icon, size: 16, color: mode == selected ? AppColors.white : AppColors.textMuted),
              selected: mode == selected,
              onSelected: (_) => onSelected(mode),
              selectedColor: AppColors.red.withValues(alpha: 0.18),
              side: BorderSide(color: mode == selected ? AppColors.red : AppColors.border),
              labelStyle: AppTextStyles.label.copyWith(
                color: mode == selected ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _ToneSlider extends StatelessWidget {
  const _ToneSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('TONE', style: AppTextStyles.title.copyWith(fontSize: 18)),
            const Spacer(),
            Text(toneLabel(value), style: AppTextStyles.label.copyWith(color: AppColors.red)),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          semanticFormatterCallback: (v) => 'Tone ${toneLabel(v)}',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chill', style: AppTextStyles.caption),
              Text('Bold', style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}
