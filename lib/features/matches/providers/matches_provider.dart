import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../data/match.dart';

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(Hive.box<dynamic>(HiveBoxes.matches)),
);

final matchesProvider = NotifierProvider<MatchesNotifier, List<MatchProfile>>(MatchesNotifier.new);

class MatchesNotifier extends Notifier<List<MatchProfile>> {
  MatchRepository get _repo => ref.read(matchRepositoryProvider);

  @override
  List<MatchProfile> build() => ref.watch(matchRepositoryProvider).all();

  /// Creates a match when [id] is null, otherwise updates it.
  Future<MatchProfile> save({String? id, required String name, required String notes}) async {
    final now = DateTime.now();
    final match = MatchProfile(
      id: id ?? now.microsecondsSinceEpoch.toRadixString(36),
      name: name.trim(),
      notes: notes.trim(),
      updatedAt: now,
    );
    await _repo.save(match);
    state = _repo.all();
    return match;
  }

  Future<void> delete(String id) async {
    state = [for (final m in state) if (m.id != id) m];
    await _repo.delete(id);
  }

  MatchProfile? byId(String? id) {
    if (id == null) return null;
    for (final m in state) {
      if (m.id == id) return m;
    }
    return null;
  }
}
