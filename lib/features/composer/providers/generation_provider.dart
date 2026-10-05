import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/reply_prefs.dart';
import '../../../services/api_service.dart';
import '../../history/data/generation.dart';
import '../../history/providers/history_provider.dart';
import '../../stats/providers/stats_provider.dart';
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
      final (generation, quota) = await ref.read(replyRepositoryProvider).generate(request);
      if (id != _requestId) return; // A newer request superseded this one.
      await ref.read(historyProvider.notifier).add(generation);
      state = AsyncData(generation);
      await ref.read(statsProvider.notifier).record(
            mode: request.mode,
            replies: generation.allOptions.length,
            multi: request.count > 1,
            quota: quota,
          );
    } on ApiException catch (e, st) {
      if (id != _requestId) return;
      state = AsyncError(e, st);
    } catch (e, st) {
      if (id != _requestId) return;
      state = AsyncError(const ApiException('Something went sideways. Try again.'), st);
    }
  }

  /// Rewrites option [index] of the current result. Throws [ApiException].
  Future<void> tweak(int index, ReplyTweak tweak) async {
    final request = _lastRequest;
    final current = state.value;
    if (request == null || current == null) return;
    final (option, quota) = await ref.read(replyRepositoryProvider).tweak(request, current.allOptions[index], tweak);
    if (state.value?.id != current.id) return; // The user generated something new meanwhile.
    await replaceOption(index, option);
    await ref.read(statsProvider.notifier).record(mode: request.mode, replies: 1, multi: false, quota: quota);
  }

  /// Swaps in an edited or tweaked option and updates History to match.
  Future<void> replaceOption(int index, ReplyOption option) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.withOption(index, option);
    state = AsyncData(updated);
    await ref.read(historyProvider.notifier).add(updated);
  }

  Future<void> regenerate() async {
    final request = _lastRequest;
    if (request != null) await generate(request);
  }
}
