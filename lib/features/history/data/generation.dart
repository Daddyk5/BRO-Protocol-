import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/bro_mode.dart';

/// One of the replies written for a request (Chill / Balanced / Bold).
class ReplyOption {
  const ReplyOption({required this.label, required this.tone, required this.text});

  final String label;
  final double tone;
  final String text;
}

/// One generated reply, stored in the `history` Hive box. [reply] is the main
/// (Balanced) reply; [options] holds every option when several were written.
class Generation {
  const Generation({
    required this.id,
    required this.mode,
    required this.context,
    required this.reply,
    required this.tone,
    required this.language,
    required this.createdAt,
    this.options = const [],
  });

  final String id;
  final BroMode mode;
  final String context;
  final String reply;
  final double tone;
  final AppLanguage language;
  final DateTime createdAt;
  final List<ReplyOption> options;

  /// Every option to show, falling back to [reply] for single-reply entries.
  List<ReplyOption> get allOptions =>
      options.isNotEmpty ? options : [ReplyOption(label: toneLabel(tone), tone: tone, text: reply)];

  Generation copyWith({String? reply, DateTime? createdAt, String? id}) => Generation(
        id: id ?? this.id,
        mode: mode,
        context: context,
        reply: reply ?? this.reply,
        tone: tone,
        language: language,
        createdAt: createdAt ?? this.createdAt,
        options: options,
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
      // Field 7 was added with multi-reply; older entries don't have it.
      options: [
        for (final o in (fields[7] as List?) ?? const [])
          ReplyOption(label: (o as List)[0] as String, tone: (o[1] as num).toDouble(), text: o[2] as String),
      ],
    );
  }

  @override
  void write(BinaryWriter writer, Generation obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(7)
      ..write([
        for (final o in obj.options) [o.label, o.tone, o.text],
      ]);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => other is GenerationAdapter && other.typeId == typeId;
}
