import 'package:hive/hive.dart';

import '../../../core/constants/bro_mode.dart';

/// What the backend reported after the last reply: how many are left in the
/// current hour and when the window resets.
class Quota {
  const Quota({required this.remaining, required this.limit, required this.resetAt});

  final int remaining;
  final int limit;
  final DateTime resetAt;

  /// A full allowance once the window has passed.
  Quota current(DateTime now) => now.isAfter(resetAt) ? Quota(remaining: limit, limit: limit, resetAt: resetAt) : this;
}

/// One request: when, which mode, how many replies it wrote.
class UsageEvent {
  const UsageEvent({required this.at, required this.mode, required this.replies, required this.multi});

  final DateTime at;
  final BroMode mode;
  final int replies;

  /// Asked for several options at once (3 options / date ideas).
  final bool multi;
}

/// Everything the Stats screen shows, computed on the device.
class UsageSummary {
  const UsageSummary({
    required this.thisWeek,
    required this.allTime,
    required this.requests,
    required this.byMode,
    required this.multiShare,
    required this.activeDays,
    this.quota,
  });

  /// Replies written in the last 7 days.
  final int thisWeek;
  final int allTime;
  final int requests;

  /// Replies per mode, most used first.
  final List<(BroMode, int)> byMode;

  /// Share of requests that asked for several options (0..1).
  final double multiShare;

  /// Distinct days with at least one request.
  final int activeDays;
  final Quota? quota;

  static UsageSummary from(List<UsageEvent> events, {Quota? quota, required DateTime now}) {
    final weekAgo = now.subtract(const Duration(days: 7));
    final perMode = <BroMode, int>{};
    var allTime = 0;
    var thisWeek = 0;
    var multi = 0;
    final days = <String>{};
    for (final e in events) {
      allTime += e.replies;
      if (e.at.isAfter(weekAgo)) thisWeek += e.replies;
      if (e.multi) multi += 1;
      perMode[e.mode] = (perMode[e.mode] ?? 0) + e.replies;
      days.add('${e.at.year}-${e.at.month}-${e.at.day}');
    }
    final byMode = perMode.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));
    return UsageSummary(
      thisWeek: thisWeek,
      allTime: allTime,
      requests: events.length,
      byMode: byMode,
      multiShare: events.isEmpty ? 0 : multi / events.length,
      activeDays: days.length,
      quota: quota?.current(now),
    );
  }
}

/// Stores usage events and the last quota in a plain `Box<dynamic>`.
class StatsRepository {
  StatsRepository(this._box);

  final Box<dynamic> _box;

  static const _events = 'events';
  static const _quota = 'quota';

  /// Keeps the log small; older events only matter for the all-time count.
  static const maxEvents = 2000;

  List<UsageEvent> events() {
    final raw = _box.get(_events);
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is List && e.length >= 4)
          UsageEvent(
            at: DateTime.fromMillisecondsSinceEpoch(e[0] as int),
            mode: BroMode.fromApi(e[1] as String),
            replies: e[2] as int,
            multi: e[3] as bool,
          ),
    ];
  }

  Future<void> record(UsageEvent event) async {
    final raw = (_box.get(_events) as List?)?.toList() ?? [];
    raw.add([event.at.millisecondsSinceEpoch, event.mode.apiValue, event.replies, event.multi]);
    if (raw.length > maxEvents) raw.removeRange(0, raw.length - maxEvents);
    await _box.put(_events, raw);
  }

  Quota? quota() {
    final raw = _box.get(_quota);
    if (raw is! Map) return null;
    return Quota(
      remaining: raw['remaining'] as int,
      limit: raw['limit'] as int,
      resetAt: DateTime.fromMillisecondsSinceEpoch(raw['resetAt'] as int),
    );
  }

  Future<void> setQuota(Quota quota) => _box.put(_quota, {
        'remaining': quota.remaining,
        'limit': quota.limit,
        'resetAt': quota.resetAt.millisecondsSinceEpoch,
      });

  Future<void> clear() async {
    await _box.clear();
  }
}
