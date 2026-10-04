import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppRadii {
  static const double card = 16;
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOut;
  static const double pressedScale = 0.97;

  /// Collapses durations to zero when the OS asks for reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final textTheme = _inter(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    const colorScheme = ColorScheme.dark(
      primary: AppColors.red,
      onPrimary: AppColors.white,
      secondary: AppColors.blue,
      onSecondary: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textMuted,
      surfaceContainerHighest: AppColors.surface2,
      surfaceContainerHigh: AppColors.surface2,
      surfaceContainer: AppColors.surface,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: AppColors.red,
      onError: AppColors.white,
    );

    const stadium = StadiumBorder();

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.text),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardRadius,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTextStyles.bodyMuted,
        contentPadding: const EdgeInsets.all(16),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: BorderSide(color: AppColors.blue, width: 1.5),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.red,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.white,
        overlayColor: AppColors.red.withValues(alpha: 0.16),
        trackHeight: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.surface2,
        side: const BorderSide(color: AppColors.border),
        shape: stadium,
        labelStyle: AppTextStyles.label,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          shape: stadium,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: AppTextStyles.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.text,
          shape: stadium,
          textStyle: AppTextStyles.label,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: AppColors.white,
          shape: stadium,
          minimumSize: const Size(48, 48),
          textStyle: AppTextStyles.label,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textMuted,
          selectedBackgroundColor: AppColors.surface2,
          selectedForegroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          shape: stadium,
          textStyle: AppTextStyles.label,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface2,
        contentTextStyle: AppTextStyles.label,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.cardRadius,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
        titleTextStyle: AppTextStyles.title,
        contentTextStyle: AppTextStyles.body,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textMuted,
        textColor: AppColors.text,
        titleTextStyle: AppTextStyles.body,
        subtitleTextStyle: AppTextStyles.caption,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.red),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Applies Inter to every style while keeping each style's size and weight.
  static TextTheme _inter(TextTheme t) => t.copyWith(
        displayLarge: GoogleFonts.inter(textStyle: t.displayLarge),
        displayMedium: GoogleFonts.inter(textStyle: t.displayMedium),
        displaySmall: GoogleFonts.inter(textStyle: t.displaySmall),
        headlineLarge: GoogleFonts.inter(textStyle: t.headlineLarge),
        headlineMedium: GoogleFonts.inter(textStyle: t.headlineMedium),
        headlineSmall: GoogleFonts.inter(textStyle: t.headlineSmall),
        titleLarge: GoogleFonts.inter(textStyle: t.titleLarge),
        titleMedium: GoogleFonts.inter(textStyle: t.titleMedium),
        titleSmall: GoogleFonts.inter(textStyle: t.titleSmall),
        bodyLarge: GoogleFonts.inter(textStyle: t.bodyLarge),
        bodyMedium: GoogleFonts.inter(textStyle: t.bodyMedium),
        bodySmall: GoogleFonts.inter(textStyle: t.bodySmall),
        labelLarge: GoogleFonts.inter(textStyle: t.labelLarge),
        labelMedium: GoogleFonts.inter(textStyle: t.labelMedium),
        labelSmall: GoogleFonts.inter(textStyle: t.labelSmall),
      );
}
