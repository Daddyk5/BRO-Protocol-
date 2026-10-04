import 'package:flutter/material.dart';

/// Night-ops palette shared by the app, the Chrome extension and the icons.
abstract final class AppColors {
  static const Color bg = Color(0xFF0B0D12);
  static const Color surface = Color(0xFF151922);
  static const Color surface2 = Color(0xFF1E2430);
  static const Color border = Color(0xFF2A3140);
  static const Color text = Color(0xFFF1F3F7);
  static const Color textMuted = Color(0xFF8A93A6);
  static const Color red = Color(0xFFE63946);
  static const Color blue = Color(0xFF1D4ED8);
  static const Color white = Color(0xFFFFFFFF);

  /// 135° red → blue (CSS `linear-gradient(135deg, red, blue)`).
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, blue],
  );

  /// Glow used under primary (gradient) buttons.
  static List<BoxShadow> get gradientGlow => [
        BoxShadow(
          color: red.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(-6, 8),
        ),
        BoxShadow(
          color: blue.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(6, 8),
        ),
      ];
}
