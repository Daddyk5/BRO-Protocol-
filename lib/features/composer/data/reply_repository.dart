import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bro_mode.dart';
import '../../../core/constants/reply_prefs.dart';
import '../../../services/api_service.dart';
import '../../history/data/generation.dart';
import '../../stats/data/usage_stats.dart';

class ReplyRequest {
  const ReplyRequest({
    required this.mode,
    required this.context,
    required this.tone,
    required this.language,
    this.count = 1,
    this.tips = false,
    this.notes,
    this.prefs = const ReplyPrefs(),
  });

  final BroMode mode;
  final String context;
  final double tone;
  final AppLanguage language;

  /// 3 asks for Chill / Balanced / Bold options; 1 writes one reply at [tone].
  final int count;

  /// Ask for a "why this works" line per reply.
  final bool tips;

  /// Notes about the selected match, sent as context for the reply.
  final String? notes;

  /// Emoji, length and the user's own style, from Settings.
  final ReplyPrefs prefs;
}

final replyRepositoryProvider = Provider<ReplyRepository>(
  (ref) => ReplyRepository(ref.watch(apiServiceProvider)),
);

class ReplyRepository {
  ReplyRepository(this._api);

  final ApiService _api;

  Future<(Generation, Quota?)> generate(ReplyRequest request) async {
    final batch = await _api.generateReplies(
      mode: request.mode,
      context: request.context,
      tone: request.tone,
      language: request.language,
      count: request.count,
      tips: request.tips,
      notes: request.notes,
      prefs: request.prefs,
    );
    final options = batch.options;
    final main = options.firstWhere((o) => o.label == 'Balanced', orElse: () => options.first);
    final now = DateTime.now();
    final generation = Generation(
      id: now.microsecondsSinceEpoch.toRadixString(36),
      mode: request.mode,
      context: request.context,
      reply: main.text,
      tone: main.tone,
      language: request.language,
      createdAt: now,
      options: options,
    );
    return (generation, batch.quota);
  }

  /// Rewrites [option] with [tweak], keeping its label and tone.
  Future<(ReplyOption, Quota?)> tweak(ReplyRequest request, ReplyOption option, ReplyTweak tweak) async {
    final batch = await _api.generateReplies(
      mode: request.mode,
      context: request.context,
      tone: option.tone,
      language: request.language,
      tips: request.tips,
      notes: request.notes,
      prefs: request.prefs,
      tweak: tweak,
      previous: option.text,
    );
    final rewritten = batch.options.first;
    return (ReplyOption(label: option.label, tone: option.tone, text: rewritten.text, tip: rewritten.tip), batch.quota);
  }
}
