import 'package:flutter/material.dart';

import '../../core/constants/bro_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pressable_scale.dart';

class ModeCard extends StatelessWidget {
  const ModeCard({super.key, required this.mode, required this.onTap});

  final BroMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${mode.title}. ${mode.description}',
      excludeSemantics: true,
      child: PressableScale(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.cardRadius,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                    child: Icon(mode.icon, color: AppColors.white, size: 22),
                  ),
                  const SizedBox(height: 14),
                  Text(mode.title, style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(mode.description, style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
