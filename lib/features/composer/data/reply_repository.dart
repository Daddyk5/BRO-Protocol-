import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bro_mode.dart';
import '../../../services/api_service.dart';
import '../../history/data/generation.dart';

class ReplyRequest {
  const ReplyRequest({
    required this.mode,
    required this.context,
    required this.tone,
    required this.language,
    this.count = 1,
  });

  final BroMode mode;
  final String context;
  final double tone;
  final AppLanguage language;

  /// 3 asks for Chill / Balanced / Bold options; 1 writes one reply at [tone].
  final int count;
}

final replyRepositoryProvider = Provider<ReplyRepository>(
  (ref) => ReplyRepository(ref.watch(apiServiceProvider)),
);

class ReplyRepository {
  ReplyRepository(this._api);

  final ApiService _api;

  Future<Generation> generate(ReplyRequest request) async {
    final options = await _api.generateReplies(
      mode: request.mode,
      context: request.context,
      tone: request.tone,
      language: request.language,
      count: request.count,
    );
    final main = options.firstWhere((o) => o.label == 'Balanced', orElse: () => options.first);
    final now = DateTime.now();
    return Generation(
      id: now.microsecondsSinceEpoch.toRadixString(36),
      mode: request.mode,
      context: request.context,
      reply: main.text,
      tone: main.tone,
      language: request.language,
      createdAt: now,
      options: options.length > 1 ? options : const [],
    );
  }
}
