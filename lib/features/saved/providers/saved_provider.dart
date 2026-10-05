import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/bro_mode.dart';
import '../data/saved_reply.dart';

final savedRepositoryProvider = Provider<SavedRepository>(
  (ref) => SavedRepository(Hive.box<dynamic>(HiveBoxes.saved)),
);

final savedProvider = NotifierProvider<SavedNotifier, List<SavedReply>>(SavedNotifier.new);

class SavedNotifier extends Notifier<List<SavedReply>> {
  SavedRepository get _repo => ref.read(savedRepositoryProvider);

  @override
  List<SavedReply> build() => ref.watch(savedRepositoryProvider).all();

  bool isSaved(String text) => state.any((s) => s.text == text);

  /// Stars [text], or un-stars it if it's already saved. Returns the new state.
  Future<bool> toggle({required String text, required BroMode mode, required String label}) async {
    final existing = state.where((s) => s.text == text).toList();
    if (existing.isNotEmpty) {
      for (final s in existing) {
        await _repo.delete(s.id);
      }
      state = _repo.all();
      return false;
    }
    final now = DateTime.now();
    await _repo.save(
      SavedReply(id: now.microsecondsSinceEpoch.toRadixString(36), text: text, mode: mode, label: label, savedAt: now),
    );
    state = _repo.all();
    return true;
  }

  Future<void> delete(String id) async {
    state = [for (final s in state) if (s.id != id) s];
    await _repo.delete(id);
  }

  Future<void> clear() async {
    await _repo.clear();
    state = const [];
  }
}
