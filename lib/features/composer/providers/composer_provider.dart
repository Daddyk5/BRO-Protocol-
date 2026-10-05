import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bro_mode.dart';
import '../../settings/providers/settings_provider.dart';

class ComposerState {
  const ComposerState({required this.mode, required this.text, required this.tone, this.threeOptions = true});

  final BroMode mode;
  final String text;
  final double tone;

  /// Write Chill / Balanced / Bold options at once instead of one reply at [tone].
  final bool threeOptions;

  bool get canGenerate => text.trim().isNotEmpty;

  ComposerState copyWith({BroMode? mode, String? text, double? tone, bool? threeOptions}) => ComposerState(
        mode: mode ?? this.mode,
        text: text ?? this.text,
        tone: tone ?? this.tone,
        threeOptions: threeOptions ?? this.threeOptions,
      );
}

final composerProvider = NotifierProvider<ComposerController, ComposerState>(ComposerController.new);

class ComposerController extends Notifier<ComposerState> {
  @override
  ComposerState build() => ComposerState(
        mode: BroMode.banter,
        text: '',
        tone: ref.read(settingsProvider).defaultTone,
      );

  void setMode(BroMode mode) => state = state.copyWith(mode: mode);

  void setText(String text) => state = state.copyWith(text: text);

  void setTone(double tone) => state = state.copyWith(tone: tone);

  void setThreeOptions(bool value) => state = state.copyWith(threeOptions: value);

  /// Starts a fresh draft in [mode], keeping nothing from the previous one.
  void start(BroMode mode) => state = ComposerState(
        mode: mode,
        text: '',
        tone: ref.read(settingsProvider).defaultTone,
        threeOptions: state.threeOptions,
      );

  /// Used by the share-sheet flow: text from Messenger, BANTER preselected.
  void prefill(String text, BroMode mode) => state = ComposerState(
        mode: mode,
        text: text,
        tone: ref.read(settingsProvider).defaultTone,
        threeOptions: state.threeOptions,
      );

  void appendText(String extra) {
    final current = state.text.trimRight();
    state = state.copyWith(text: current.isEmpty ? extra : '$current\n$extra');
  }
}
