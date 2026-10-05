import 'dart:io';

import 'package:bro_protocol/core/constants/app_constants.dart';
import 'package:bro_protocol/core/constants/bro_mode.dart';
import 'package:bro_protocol/core/constants/reply_prefs.dart';
import 'package:bro_protocol/features/history/data/generation.dart';
import 'package:bro_protocol/features/history/data/history_repository.dart';
import 'package:bro_protocol/features/matches/data/match.dart';
import 'package:bro_protocol/features/saved/data/saved_reply.dart';
import 'package:bro_protocol/features/stats/data/usage_stats.dart';
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

  test('Reply options round-trip; single replies fall back to one option', () async {
    const options = [
      ReplyOption(label: 'Chill', tone: 0.15, text: 'chill one'),
      ReplyOption(label: 'Balanced', tone: 0.5, text: 'balanced one'),
      ReplyOption(label: 'Bold', tone: 0.85, text: 'bold one'),
    ];
    final multi = Generation(
      id: 'm1',
      mode: BroMode.lateNight,
      context: 'up late?',
      reply: 'balanced one',
      tone: 0.5,
      language: AppLanguage.english,
      createdAt: DateTime(2026, 1, 1),
      options: options,
    );
    final box = await Hive.openBox<Generation>('history');
    await box.put('m1', multi);
    await box.put('g1', make(1));
    await box.close();

    final reopened = await Hive.openBox<Generation>('history');
    final m = reopened.get('m1')!;
    expect(m.mode, BroMode.lateNight);
    expect(m.allOptions.map((o) => o.label), ['Chill', 'Balanced', 'Bold']);
    expect(m.allOptions.last.text, 'bold one');

    final single = reopened.get('g1')!.allOptions;
    expect(single.length, 1);
    expect(single.single.label, 'Balanced');
    expect(single.single.text, 'reply 1');
  });

  test('Tips survive the adapter', () async {
    final g = Generation(
      id: 't1',
      mode: BroMode.dateIdeas,
      context: 'she loves ramen',
      reply: 'Ramen Friday?',
      tone: 0.5,
      language: AppLanguage.english,
      createdAt: DateTime(2026, 1, 1),
      options: const [ReplyOption(label: 'Evening', tone: 0.5, text: 'Ramen Friday?', tip: 'Uses what she loves.')],
    );
    final box = await Hive.openBox<Generation>('history');
    await box.put('t1', g);
    await box.close();

    final option = (await Hive.openBox<Generation>('history')).get('t1')!.allOptions.single;
    expect(option.label, 'Evening');
    expect(option.tip, 'Uses what she loves.');
  });

  test('Match notes are capped and include the name', () async {
    final box = await Hive.openBox<dynamic>('matches');
    final repo = MatchRepository(box);
    await repo.save(MatchProfile(id: 'a', name: 'Mia', notes: '', updatedAt: DateTime(2026, 1, 1)));
    await repo.save(MatchProfile(id: 'b', name: 'Jo', notes: 'x' * 2000, updatedAt: DateTime(2026, 1, 2)));

    final all = repo.all();
    expect(all.map((m) => m.id), ['b', 'a']);
    expect(all.last.promptNotes, 'Name: Mia.');
    expect(all.first.promptNotes.length, AppConstants.maxNotesLength);
  });

  test('Usage summary counts the week, modes and multi-option share', () {
    final now = DateTime(2026, 10, 5, 12);
    final summary = UsageSummary.from(
      [
        UsageEvent(at: now.subtract(const Duration(days: 10)), mode: BroMode.banter, replies: 1, multi: false),
        UsageEvent(at: now.subtract(const Duration(days: 1)), mode: BroMode.banter, replies: 3, multi: true),
        UsageEvent(at: now, mode: BroMode.dateIdeas, replies: 3, multi: true),
        UsageEvent(at: now, mode: BroMode.banter, replies: 1, multi: false),
      ],
      quota: Quota(remaining: 2, limit: 20, resetAt: now.subtract(const Duration(minutes: 1))),
      now: now,
    );
    expect(summary.allTime, 8);
    expect(summary.thisWeek, 7);
    expect(summary.byMode.first, (BroMode.banter, 5));
    expect(summary.multiShare, 0.5);
    expect(summary.activeDays, 3);
    expect(summary.quota!.remaining, 20, reason: 'the window has passed, so the full allowance is back');
  });

  test('Replacing an option keeps the rest and follows the main reply', () {
    final g = Generation(
      id: 'x',
      mode: BroMode.banter,
      context: 'hey',
      reply: 'balanced',
      tone: 0.5,
      language: AppLanguage.english,
      createdAt: DateTime(2026, 1, 1),
      options: const [
        ReplyOption(label: 'Chill', tone: 0.15, text: 'chill'),
        ReplyOption(label: 'Balanced', tone: 0.5, text: 'balanced', tip: 'old tip'),
        ReplyOption(label: 'Bold', tone: 0.85, text: 'bold'),
      ],
    );
    final edited = g.withOption(1, g.options[1].withText('balanced, edited'));
    expect(edited.reply, 'balanced, edited');
    expect(edited.options[1].tip, isNull, reason: 'the tip explained the old text');
    expect(edited.options.map((o) => o.text), ['chill', 'balanced, edited', 'bold']);
  });

  test('Saved replies round-trip, newest first', () async {
    final repo = SavedRepository(await Hive.openBox<dynamic>('saved'));
    await repo.save(SavedReply(id: 'a', text: 'one', mode: BroMode.revive, label: 'Chill', savedAt: DateTime(2026, 1, 1)));
    await repo.save(SavedReply(id: 'b', text: 'two', mode: BroMode.lateNight, label: 'Bold', savedAt: DateTime(2026, 1, 2)));
    final all = repo.all();
    expect(all.map((s) => s.text), ['two', 'one']);
    expect(all.first.mode, BroMode.lateNight);
  });

  test('Preferences only send what is set', () {
    expect(const ReplyPrefs().toJson(), {'emoji': true});
    expect(const ReplyPrefs(allowEmoji: false, short: true, style: '  dry  ').toJson(), {
      'emoji': false,
      'short': true,
      'style': 'dry',
    });
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
