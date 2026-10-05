import 'package:hive/hive.dart';

import '../../../core/constants/bro_mode.dart';

/// A reply the user starred. Kept until they remove it (unlike History,
/// which only keeps the latest few).
class SavedReply {
  const SavedReply({required this.id, required this.text, required this.mode, required this.label, required this.savedAt});

  final String id;
  final String text;
  final BroMode mode;

  /// The option it came from, e.g. "Bold" or "Evening".
  final String label;
  final DateTime savedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'mode': mode.apiValue,
        'label': label,
        'savedAt': savedAt.millisecondsSinceEpoch,
      };

  static SavedReply fromMap(Map<dynamic, dynamic> map) => SavedReply(
        id: map['id'] as String,
        text: map['text'] as String,
        mode: BroMode.fromApi(map['mode'] as String),
        label: (map['label'] as String?) ?? '',
        savedAt: DateTime.fromMillisecondsSinceEpoch(map['savedAt'] as int),
      );
}

class SavedRepository {
  SavedRepository(this._box);

  final Box<dynamic> _box;

  /// Newest first.
  List<SavedReply> all() {
    final items = [
      for (final value in _box.values)
        if (value is Map) SavedReply.fromMap(value),
    ]..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return items;
  }

  Future<void> save(SavedReply reply) => _box.put(reply.id, reply.toMap());

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() async {
    await _box.clear();
  }
}
