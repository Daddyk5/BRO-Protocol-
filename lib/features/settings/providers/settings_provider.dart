import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/bro_mode.dart';
import '../../../core/constants/reply_prefs.dart';

class AppSettings {
  const AppSettings({
    required this.defaultTone,
    required this.language,
    this.showTips = true,
    this.onboardingDone = false,
    this.allowEmoji = true,
    this.shortReplies = false,
    this.styleNotes = '',
    this.haptics = true,
  });

  final double defaultTone;
  final AppLanguage language;

  /// Show a one-line "why this works" under each reply.
  final bool showTips;

  /// The user finished onboarding and accepted the current terms version.
  final bool onboardingDone;

  final bool allowEmoji;
  final bool shortReplies;

  /// How the user texts, in their own words ("dry, lowercase, no exclamation marks").
  final String styleNotes;

  /// Light vibration on copy and generate (phones only).
  final bool haptics;

  ReplyPrefs get prefs => ReplyPrefs(allowEmoji: allowEmoji, short: shortReplies, style: styleNotes);

  AppSettings copyWith({
    double? defaultTone,
    AppLanguage? language,
    bool? showTips,
    bool? onboardingDone,
    bool? allowEmoji,
    bool? shortReplies,
    String? styleNotes,
    bool? haptics,
  }) =>
      AppSettings(
        defaultTone: defaultTone ?? this.defaultTone,
        language: language ?? this.language,
        showTips: showTips ?? this.showTips,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        allowEmoji: allowEmoji ?? this.allowEmoji,
        shortReplies: shortReplies ?? this.shortReplies,
        styleNotes: styleNotes ?? this.styleNotes,
        haptics: haptics ?? this.haptics,
      );
}

abstract final class _Keys {
  static const tone = 'defaultTone';
  static const language = 'language';
  static const deviceId = 'deviceId';
  static const showTips = 'showTips';
  static const acceptedTerms = 'acceptedTermsVersion';
  static const allowEmoji = 'allowEmoji';
  static const shortReplies = 'shortReplies';
  static const styleNotes = 'styleNotes';
  static const haptics = 'haptics';
}

final settingsBoxProvider = Provider<Box<dynamic>>((ref) => Hive.box<dynamic>(HiveBoxes.settings));

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  Box<dynamic> get _box => ref.read(settingsBoxProvider);

  @override
  AppSettings build() {
    final box = ref.watch(settingsBoxProvider);
    return AppSettings(
      defaultTone: (box.get(_Keys.tone, defaultValue: 0.5) as num).toDouble(),
      language: AppLanguage.fromApi(box.get(_Keys.language) as String?),
      showTips: box.get(_Keys.showTips, defaultValue: true) as bool,
      onboardingDone: (box.get(_Keys.acceptedTerms, defaultValue: 0) as int) >= AppConstants.termsVersion,
      allowEmoji: box.get(_Keys.allowEmoji, defaultValue: true) as bool,
      shortReplies: box.get(_Keys.shortReplies, defaultValue: false) as bool,
      styleNotes: box.get(_Keys.styleNotes, defaultValue: '') as String,
      haptics: box.get(_Keys.haptics, defaultValue: true) as bool,
    );
  }

  Future<void> setAllowEmoji(bool value) async {
    state = state.copyWith(allowEmoji: value);
    await _box.put(_Keys.allowEmoji, value);
  }

  Future<void> setShortReplies(bool value) async {
    state = state.copyWith(shortReplies: value);
    await _box.put(_Keys.shortReplies, value);
  }

  Future<void> setStyleNotes(String value) async {
    final trimmed = value.trim();
    state = state.copyWith(styleNotes: trimmed);
    await _box.put(_Keys.styleNotes, trimmed);
  }

  Future<void> setHaptics(bool value) async {
    state = state.copyWith(haptics: value);
    await _box.put(_Keys.haptics, value);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
    await _box.put(_Keys.acceptedTerms, AppConstants.termsVersion);
  }

  /// Wipes every setting, including the install ID and the terms acceptance.
  Future<void> reset() async {
    await _box.clear();
    ref.invalidate(deviceIdProvider);
    ref.invalidateSelf();
  }

  Future<void> setShowTips(bool value) async {
    state = state.copyWith(showTips: value);
    await _box.put(_Keys.showTips, value);
  }

  Future<void> setDefaultTone(double tone) async {
    state = state.copyWith(defaultTone: tone);
    await _box.put(_Keys.tone, tone);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await _box.put(_Keys.language, language.apiValue);
  }
}

/// Stable, random per-install ID used by the backend's per-device rate limit.
final deviceIdProvider = Provider<String>((ref) {
  final box = ref.watch(settingsBoxProvider);
  final existing = box.get(_Keys.deviceId) as String?;
  if (existing != null && existing.isNotEmpty) return existing;
  final random = Random.secure();
  final id = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  box.put(_Keys.deviceId, id);
  return id;
});
