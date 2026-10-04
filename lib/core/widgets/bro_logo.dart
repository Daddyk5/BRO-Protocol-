import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum BroLogoVariant { full, icon, mono }

abstract final class BroAssets {
  static const String logo = 'assets/logo/bro_logo.svg';
  static const String logoMono = 'assets/logo/bro_logo_mono.svg';
  static const String fistRed = 'assets/logo/fist_red.svg';
  static const String fistBlue = 'assets/logo/fist_blue.svg';
}

/// Two fists bumping head-on: red left, blue right, white spark at contact.
///
/// * [BroLogoVariant.icon]: the mark only.
/// * [BroLogoVariant.full]: the mark plus the "BRO PROTOCOL" wordmark.
/// * [BroLogoVariant.mono]: all-white mark, for photos or colored backgrounds.
class BroLogo extends StatelessWidget {
  const BroLogo({super.key, this.variant = BroLogoVariant.icon, this.size = 48});

  const BroLogo.full({super.key, this.size = 36}) : variant = BroLogoVariant.full;

  const BroLogo.mono({super.key, this.size = 48}) : variant = BroLogoVariant.mono;

  final BroLogoVariant variant;

  /// Height of the mark in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final mark = SvgPicture.asset(
      variant == BroLogoVariant.mono ? BroAssets.logoMono : BroAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );

    if (variant != BroLogoVariant.full) {
      return Semantics(label: 'Bro Protocol logo', image: true, child: mark);
    }

    return Semantics(
      label: 'Bro Protocol',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(width: 8),
          Text(
            AppConstants.appName,
            style: AppTextStyles.title.copyWith(
              fontSize: size * 0.62,
              letterSpacing: 2,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
