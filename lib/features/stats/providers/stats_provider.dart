import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/bro_mode.dart';
import '../data/usage_stats.dart';

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => StatsRepository(Hive.box<dynamic>(HiveBoxes.stats)),
);

final statsProvider = NotifierProvider<StatsNotifier, UsageSummary>(StatsNotifier.new);

class StatsNotifier extends Notifier<UsageSummary> {
  StatsRepository get _repo => ref.read(statsRepositoryProvider);

  @override
  UsageSummary build() {
    final repo = ref.watch(statsRepositoryProvider);
    return UsageSummary.from(repo.events(), quota: repo.quota(), now: DateTime.now());
  }

  Future<void> record({required BroMode mode, required int replies, required bool multi, Quota? quota}) async {
    await _repo.record(UsageEvent(at: DateTime.now(), mode: mode, replies: replies, multi: multi));
    if (quota != null) await _repo.setQuota(quota);
    _refresh();
  }

  Future<void> clear() async {
    await _repo.clear();
    _refresh();
  }

  /// Recomputes, e.g. when the Stats screen opens after the quota window reset.
  void refresh() => _refresh();

  void _refresh() => state = UsageSummary.from(_repo.events(), quota: _repo.quota(), now: DateTime.now());
}
