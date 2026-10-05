import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../matches/providers/matches_provider.dart';
import '../../saved/providers/saved_provider.dart';
import '../data/usage_stats.dart';
import '../providers/stats_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    // The hourly window may have reset since the last reply.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(statsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final saved = ref.watch(savedProvider).length;
    final matches = ref.watch(matchesProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('YOUR STATS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (stats.quota case final quota?) ...[
              _QuotaCard(quota: quota),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(child: _StatTile(value: '${stats.thisWeek}', label: 'Replies this week')),
                const SizedBox(width: 12),
                Expanded(child: _StatTile(value: '${stats.allTime}', label: 'Replies all time')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatTile(value: '${stats.activeDays}', label: 'Active days')),
                const SizedBox(width: 12),
                Expanded(child: _StatTile(value: '$saved', label: 'Saved')),
                const SizedBox(width: 12),
                Expanded(child: _StatTile(value: '$matches', label: 'Matches')),
              ],
            ),
            const _Header('TOP PLAYS'),
            if (stats.byMode.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Generate a few replies and your favourite plays show up here.',
                      style: AppTextStyles.bodyMuted),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      for (final (mode, count) in stats.byMode)
                        _ModeBar(
                          icon: mode.icon,
                          label: mode.title,
                          count: count,
                          fraction: count / stats.byMode.first.$2,
                        ),
                    ],
                  ),
                ),
              ),
            const _Header('HOW YOU USE IT'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.view_agenda_outlined),
                title: Text(
                  stats.requests == 0 ? 'No requests yet' : '${(stats.multiShare * 100).round()}% with 3 options',
                  style: AppTextStyles.label,
                ),
                subtitle: Text(
                  '${stats.requests} requests in total. Stats are counted on this device only.',
                  style: AppTextStyles.caption,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.quota});

  final Quota quota;

  @override
  Widget build(BuildContext context) {
    final used = quota.limit == 0 ? 0.0 : (quota.limit - quota.remaining) / quota.limit;
    final minutes = quota.resetAt.difference(DateTime.now()).inMinutes;
    final resets = quota.remaining == quota.limit
        ? 'Full allowance available'
        : minutes <= 0
            ? 'Resets any moment'
            : 'Resets in $minutes min';

    return Semantics(
      label: '${quota.remaining} of ${quota.limit} replies left this hour. $resets.',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: AppRadii.cardRadius,
          boxShadow: AppColors.gradientGlow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THIS HOUR', style: AppTextStyles.title.copyWith(color: AppColors.white, fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              '${quota.remaining} of ${quota.limit} replies left',
              style: AppTextStyles.headline.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1 - used,
                minHeight: 6,
                color: AppColors.white,
                backgroundColor: AppColors.white.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 8),
            Text(resets, style: AppTextStyles.caption.copyWith(color: AppColors.white)),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.display.copyWith(fontSize: 34)),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  const _ModeBar({required this.icon, required this.label, required this.count, required this.fraction});

  final IconData icon;
  final String label;
  final int count;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $count replies',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: AppTextStyles.label)),
                Text('$count', style: AppTextStyles.label),
              ],
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) => Container(
                height: 8,
                width: constraints.maxWidth,
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * fraction.clamp(0.04, 1.0),
                  decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Semantics(header: true, child: Text(text, style: AppTextStyles.title.copyWith(fontSize: 18))),
    );
  }
}
