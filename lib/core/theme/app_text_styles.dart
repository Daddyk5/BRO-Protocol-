import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Bebas Neue for headings, Inter for body copy.
abstract final class AppTextStyles {
  static TextStyle get display => GoogleFonts.bebasNeue(
        fontSize: 44,
        letterSpacing: 3,
        height: 1.0,
        color: AppColors.text,
      );

  static TextStyle get headline => GoogleFonts.bebasNeue(
        fontSize: 30,
        letterSpacing: 1.5,
        height: 1.05,
        color: AppColors.text,
      );

  static TextStyle get title => GoogleFonts.bebasNeue(
        fontSize: 22,
        letterSpacing: 1.2,
        height: 1.1,
        color: AppColors.text,
      );

  static TextStyle get button => GoogleFonts.bebasNeue(
        fontSize: 20,
        letterSpacing: 2,
        height: 1.0,
        color: AppColors.white,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        height: 1.45,
        color: AppColors.text,
      );

  static TextStyle get bodyMuted => GoogleFonts.inter(
        fontSize: 14,
        height: 1.45,
        color: AppColors.textMuted,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.text,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        height: 1.35,
        color: AppColors.textMuted,
      );

  static TextStyle get bubble => GoogleFonts.inter(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      );
}
