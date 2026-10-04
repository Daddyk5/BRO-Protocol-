import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import 'generation.dart';

/// Keeps the most recent [AppConstants.historyLimit] generations on-device.
class HistoryRepository {
  HistoryRepository(this._box);

  final Box<Generation> _box;

  List<Generation> all() {
    final items = _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> add(Generation generation) async {
    await _box.put(generation.id, generation);
    final items = all();
    if (items.length > AppConstants.historyLimit) {
      final stale = items.skip(AppConstants.historyLimit).map((g) => g.id).toList();
      await _box.deleteAll(stale);
    }
  }

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() async {
    await _box.clear();
  }
}
