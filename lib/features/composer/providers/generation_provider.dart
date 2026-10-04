import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_service.dart';
import '../../history/data/generation.dart';
import '../../history/providers/history_provider.dart';
import '../data/reply_repository.dart';

/// `AsyncData(null)` means nothing has been generated yet.
final generationProvider = NotifierProvider<GenerationController, AsyncValue<Generation?>>(GenerationController.new);

class GenerationController extends Notifier<AsyncValue<Generation?>> {
  ReplyRequest? _lastRequest;
  int _requestId = 0;

  ReplyRequest? get lastRequest => _lastRequest;

  @override
  AsyncValue<Generation?> build() => const AsyncData(null);

  Future<void> generate(ReplyRequest request) async {
    _lastRequest = request;
    final id = ++_requestId;
    state = const AsyncLoading();
    try {
      final generation = await ref.read(replyRepositoryProvider).generate(request);
      if (id != _requestId) return; // A newer request superseded this one.
      await ref.read(historyProvider.notifier).add(generation);
      state = AsyncData(generation);
    } on ApiException catch (e, st) {
      if (id != _requestId) return;
      state = AsyncError(e, st);
    } catch (e, st) {
      if (id != _requestId) return;
      state = AsyncError(const ApiException('Something went sideways. Try again.'), st);
    }
  }

  Future<void> regenerate() async {
    final request = _lastRequest;
    if (request != null) await generate(request);
  }
}
