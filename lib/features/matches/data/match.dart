import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';

/// A person you're talking to, with notes the AI can draw on (interests,
/// inside jokes, plans). Stored only on this device.
class MatchProfile {
  const MatchProfile({required this.id, required this.name, required this.notes, required this.updatedAt});

  final String id;
  final String name;
  final String notes;
  final DateTime updatedAt;

  /// What the backend sees as "Notes about her", capped to its limit.
  String get promptNotes {
    final text = notes.trim().isEmpty ? 'Name: $name.' : 'Name: $name. ${notes.trim()}';
    return text.length <= AppConstants.maxNotesLength ? text : text.substring(0, AppConstants.maxNotesLength);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'notes': notes,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  static MatchProfile fromMap(Map<dynamic, dynamic> map) => MatchProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        notes: (map['notes'] as String?) ?? '',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      );
}

/// Matches live in a plain `Box<dynamic>` of maps, so no adapter is needed.
class MatchRepository {
  MatchRepository(this._box);

  final Box<dynamic> _box;

  /// Most recently updated first.
  List<MatchProfile> all() {
    final items = [
      for (final value in _box.values)
        if (value is Map) MatchProfile.fromMap(value),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  Future<void> save(MatchProfile match) => _box.put(match.id, match.toMap());

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() async {
    await _box.clear();
  }
}
