import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/bro_mode.dart';

/// One generated reply, stored in the `history` Hive box.
class Generation {
  const Generation({
    required this.id,
    required this.mode,
    required this.context,
    required this.reply,
    required this.tone,
    required this.language,
    required this.createdAt,
  });

  final String id;
  final BroMode mode;
  final String context;
  final String reply;
  final double tone;
  final AppLanguage language;
  final DateTime createdAt;

  Generation copyWith({String? reply, DateTime? createdAt, String? id}) => Generation(
        id: id ?? this.id,
        mode: mode,
        context: context,
        reply: reply ?? this.reply,
        tone: tone,
        language: language,
        createdAt: createdAt ?? this.createdAt,
      );
}

/// Hand-written adapter (no build_runner needed). Field indexes are part of the
/// on-disk format: append new fields with new indexes, never reuse old ones.
class GenerationAdapter extends TypeAdapter<Generation> {
  @override
  final int typeId = HiveTypeIds.generation;

  @override
  Generation read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Generation(
      id: fields[0] as String,
      mode: BroMode.fromApi(fields[1] as String),
      context: fields[2] as String,
      reply: fields[3] as String,
      tone: (fields[4] as num).toDouble(),
      language: AppLanguage.fromApi(fields[5] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
    );
  }

  @override
  void write(BinaryWriter writer, Generation obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mode.apiValue)
      ..writeByte(2)
      ..write(obj.context)
      ..writeByte(3)
      ..write(obj.reply)
      ..writeByte(4)
      ..write(obj.tone)
      ..writeByte(5)
      ..write(obj.language.apiValue)
      ..writeByte(6)
      ..write(obj.createdAt.millisecondsSinceEpoch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => other is GenerationAdapter && other.typeId == typeId;
}
