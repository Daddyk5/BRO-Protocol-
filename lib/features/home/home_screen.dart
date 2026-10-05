import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/bro_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/bro_logo.dart';
import '../../services/share_intent_service.dart';
import '../composer/providers/composer_provider.dart';
import '../saved/providers/saved_provider.dart';
import '../stats/providers/stats_provider.dart';
import 'mode_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // A share may have arrived while the splash was still playing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _routeShare(ref.read(incomingShareProvider));
    });
  }

  void _routeShare(String? text) {
    if (text == null) return;
    ref.read(incomingShareProvider.notifier).clear();
    // The composer was already prefilled when the share arrived; `go`
    // resets the stack to Home → Composer from wherever the user was.
    context.go('/home/composer');
  }

  void _openMode(BroMode mode) {
    ref.read(composerProvider.notifier).start(mode);
    context.push('/home/composer');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(incomingShareProvider, (_, next) => _routeShare(next));

    return Scaffold(
      appBar: AppBar(
        title: const BroLogo.full(size: 34),
        actions: [
          IconButton(
            tooltip: 'Matches',
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () => context.push('/home/matches'),
          ),
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/home/history'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/home/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Semantics(
              header: true,
              child: ShaderMask(
                shaderCallback: (bounds) => AppColors.gradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(AppConstants.tagline.toUpperCase(), style: AppTextStyles.headline),
              ),
            ),
            const SizedBox(height: 4),
            Text('Pick your play.', style: AppTextStyles.bodyMuted),
            const SizedBox(height: 20),
            _ModeRow(left: BroMode.opener, right: BroMode.banter, onTap: _openMode),
            const SizedBox(height: 12),
            _ModeRow(left: BroMode.moveOffApp, right: BroMode.revive, onTap: _openMode),
            const SizedBox(height: 12),
            _ModeRow(left: BroMode.improveDraft, right: BroMode.dateIdeas, onTap: _openMode),
            const SizedBox(height: 12),
            ModeCard(mode: BroMode.lateNight, onTap: () => _openMode(BroMode.lateNight)),
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.star_rounded,
                      title: 'SAVED',
                      subtitle: '${ref.watch(savedProvider).length} replies',
                      onTap: () => context.push('/home/saved'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.insights_rounded,
                      title: 'YOUR STATS',
                      subtitle: '${ref.watch(statsProvider).thisWeek} this week',
                      onTap: () => context.push('/home/stats'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _ShareTipCard(),
          ],
        ),
      ),
    );
  }
}

/// One row of the 2x2 grid. IntrinsicHeight keeps both cards the same height
/// at any text scale, so nothing overflows on 360dp screens.
class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.left, required this.right, required this.onTap});

  final BroMode left;
  final BroMode right;
  final ValueChanged<BroMode> onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ModeCard(mode: left, onTap: () => onTap(left))),
          const SizedBox(width: 12),
          Expanded(child: ModeCard(mode: right, onTap: () => onTap(right))),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: Card(
        color: AppColors.surface2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareTipCard extends StatelessWidget {
  const _ShareTipCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.ios_share_rounded, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FASTER FROM MESSENGER', style: AppTextStyles.title.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    'Long-press her message → Share → Bro Protocol. We open BANTER with her message ready. '
                    'You copy the reply and send it yourself. Nothing is ever sent for you.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
