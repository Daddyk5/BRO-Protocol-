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
  });

  final BroMode mode;
  final String context;
  final double tone;
  final AppLanguage language;
}

final replyRepositoryProvider = Provider<ReplyRepository>(
  (ref) => ReplyRepository(ref.watch(apiServiceProvider)),
);

class ReplyRepository {
  ReplyRepository(this._api);

  final ApiService _api;

  Future<Generation> generate(ReplyRequest request) async {
    final reply = await _api.generateReply(
      mode: request.mode,
      context: request.context,
      tone: request.tone,
      language: request.language,
    );
    final now = DateTime.now();
    return Generation(
      id: now.microsecondsSinceEpoch.toRadixString(36),
      mode: request.mode,
      context: request.context,
      reply: reply,
      tone: request.tone,
      language: request.language,
      createdAt: now,
    );
  }
}
