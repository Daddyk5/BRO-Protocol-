import 'dart:io';

import 'package:bro_protocol/core/constants/bro_mode.dart';
import 'package:bro_protocol/features/history/data/generation.dart';
import 'package:bro_protocol/features/history/data/history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bro_hive_test');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(GenerationAdapter());
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  Generation make(int i) => Generation(
        id: 'g$i',
        mode: BroMode.banter,
        context: 'context $i',
        reply: 'reply $i',
        tone: 0.5,
        language: AppLanguage.taglish,
        createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
      );

  test('Generation round-trips through the Hive adapter', () async {
    final box = await Hive.openBox<Generation>('history');
    await box.put('g1', make(1));
    await box.close();

    final reopened = await Hive.openBox<Generation>('history');
    final g = reopened.get('g1')!;
    expect(g.reply, 'reply 1');
    expect(g.mode, BroMode.banter);
    expect(g.language, AppLanguage.taglish);
    expect(g.createdAt, DateTime(2026, 1, 1).add(const Duration(minutes: 1)));
  });

  test('History keeps only the newest 20, newest first', () async {
    final repo = HistoryRepository(await Hive.openBox<Generation>('history'));
    for (var i = 0; i < 25; i++) {
      await repo.add(make(i));
    }
    final all = repo.all();
    expect(all.length, 20);
    expect(all.first.id, 'g24');
    expect(all.last.id, 'g5');
  });

  test('Tone labels match the backend mapping', () {
    expect(toneLabel(0), 'Chill');
    expect(toneLabel(0.5), 'Balanced');
    expect(toneLabel(1), 'Bold');
    expect(BroMode.fromApi('MOVE_OFF_APP'), BroMode.moveOffApp);
  });
}
