import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../data/generation.dart';
import '../data/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(Hive.box<Generation>(HiveBoxes.history)),
);

final historyProvider = NotifierProvider<HistoryNotifier, List<Generation>>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<List<Generation>> {
  HistoryRepository get _repo => ref.read(historyRepositoryProvider);

  @override
  List<Generation> build() => ref.watch(historyRepositoryProvider).all();

  Future<void> add(Generation generation) async {
    await _repo.add(generation);
    state = _repo.all();
  }

  Future<void> delete(String id) async {
    state = [for (final g in state) if (g.id != id) g];
    await _repo.delete(id);
  }

  Future<void> clear() async {
    await _repo.clear();
    state = const [];
  }
}
