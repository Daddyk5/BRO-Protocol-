import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

final shareIntentServiceProvider = Provider<ShareIntentService>((ref) {
  final service = ShareIntentService();
  ref.onDispose(service.dispose);
  return service;
});

/// Text shared into the app (Messenger → long-press → Share → Bro Protocol)
/// that the Home screen has not routed to the Composer yet.
final incomingShareProvider = NotifierProvider<IncomingShareNotifier, String?>(IncomingShareNotifier.new);

class IncomingShareNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String text) => state = text;

  void clear() => state = null;
}

class ShareIntentService {
  StreamSubscription<List<SharedMediaFile>>? _subscription;

  bool get _supported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Starts listening for shares while the app is running, and delivers the
  /// share that cold-started the app (if any).
  void start(void Function(String text) onText) {
    if (!_supported || _subscription != null) return;

    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
          (files) => _deliver(files, onText),
          onError: (Object e) => debugPrint('Share intent stream error: $e'),
        );

    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _deliver(files, onText);
      ReceiveSharingIntent.instance.reset();
    }).catchError((Object e) {
      debugPrint('Share intent initial media error: $e');
    });
  }

  void _deliver(List<SharedMediaFile> files, void Function(String text) onText) {
    final text = files
        .where((f) => f.type == SharedMediaType.text || f.type == SharedMediaType.url)
        .map((f) => f.path.trim())
        .where((t) => t.isNotEmpty)
        .join('\n');
    if (text.isNotEmpty) onText(text);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
