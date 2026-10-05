import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/bro_mode.dart';

class AppSettings {
  const AppSettings({required this.defaultTone, required this.language, this.showTips = true});

  final double defaultTone;
  final AppLanguage language;

  /// Show a one-line "why this works" under each reply.
  final bool showTips;

  AppSettings copyWith({double? defaultTone, AppLanguage? language, bool? showTips}) => AppSettings(
        defaultTone: defaultTone ?? this.defaultTone,
        language: language ?? this.language,
        showTips: showTips ?? this.showTips,
      );
}

abstract final class _Keys {
  static const tone = 'defaultTone';
  static const language = 'language';
  static const deviceId = 'deviceId';
  static const showTips = 'showTips';
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
    );
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
