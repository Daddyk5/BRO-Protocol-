import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/bro_mode.dart';
import 'core/theme/app_theme.dart';
import 'features/composer/providers/composer_provider.dart';
import 'features/composer/ui/composer_screen.dart';
import 'features/composer/ui/result_screen.dart';
import 'features/history/ui/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/matches/ui/matches_screen.dart';
import 'features/settings/ui/settings_screen.dart';
import 'features/splash/splash_screen.dart';
import 'services/share_intent_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
        routes: [
          GoRoute(
            path: 'composer',
            builder: (context, state) => const ComposerScreen(),
            routes: [
              GoRoute(path: 'result', builder: (context, state) => const ResultScreen()),
            ],
          ),
          GoRoute(path: 'history', builder: (context, state) => const HistoryScreen()),
          GoRoute(path: 'matches', builder: (context, state) => const MatchesScreen()),
          GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class BroApp extends ConsumerStatefulWidget {
  const BroApp({super.key});

  @override
  ConsumerState<BroApp> createState() => _BroAppState();
}

class _BroAppState extends ConsumerState<BroApp> {
  @override
  void initState() {
    super.initState();
    // Messenger → Share → Bro Protocol: prefill BANTER with her message.
    // Home picks up incomingShareProvider and opens the Composer.
    ref.read(shareIntentServiceProvider).start((text) {
      ref.read(composerProvider.notifier).prefill(text, BroMode.banter);
      ref.read(incomingShareProvider.notifier).set(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bro Protocol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
