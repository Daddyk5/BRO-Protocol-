import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bro_logo.dart';

/// Shown instead of a blank screen when the app can't start (for example the
/// backend isn't configured). Users see a friendly message; debug builds also
/// show the technical cause.
class SetupErrorApp extends StatelessWidget {
  const SetupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bro Protocol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: _StatusBody(
          icon: Icons.cloud_off_rounded,
          title: "WE CAN'T CONNECT RIGHT NOW",
          message: 'Bro Protocol couldn\'t reach its server. Check for an update or try again in a few minutes.',
          detail: kDebugMode
              ? '$error\n\nDeveloper tip: run with --dart-define=BRO_BACKEND_URL=http://localhost:8080, '
                  'or run `flutterfire configure` for the Firebase backend.'
              : null,
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _StatusBody(
        icon: Icons.explore_off_rounded,
        title: 'NOTHING HERE',
        message: 'That page doesn\'t exist. Let\'s get you back to your plays.',
        action: FilledButton.icon(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_rounded),
          label: const Text('Go home'),
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.icon, required this.title, required this.message, this.detail, this.action});

  final IconData icon;
  final String title;
  final String message;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BroLogo(size: 64),
                const SizedBox(height: 28),
                Icon(icon, size: 36, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(title, textAlign: TextAlign.center, style: AppTextStyles.headline),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
                if (detail != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadii.cardRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SelectableText(detail!, style: AppTextStyles.caption),
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 24), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
