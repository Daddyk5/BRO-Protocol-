import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/bro_mode.dart';
import '../core/constants/reply_prefs.dart';
import '../features/history/data/generation.dart';
import '../features/settings/providers/settings_provider.dart';
import '../features/stats/data/usage_stats.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The options written for one request, plus what's left of the hourly quota.
class ReplyBatch {
  const ReplyBatch(this.options, this.quota);

  final List<ReplyOption> options;
  final Quota? quota;
}

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
});

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(dio: ref.watch(dioProvider), deviceId: ref.watch(deviceIdProvider)),
);

/// Talks to `generateReply`: the Cloud Function, or the Docker server, which
/// speaks the same HTTPS callable protocol. The app never talks to the LLM
/// directly; the API key lives only on the backend.
class ApiService {
  ApiService({required this._dio, required this._deviceId});

  final Dio _dio;
  final String _deviceId;

  String get _endpoint {
    if (AppConstants.selfHosted) {
      return '${AppConstants.broBackendUrl.replaceAll(RegExp(r'/+$'), '')}/generateReply';
    }
    if (AppConstants.functionsBaseUrlOverride.isNotEmpty) {
      return '${AppConstants.functionsBaseUrlOverride}/generateReply';
    }
    final projectId = Firebase.app().options.projectId;
    return 'https://${AppConstants.functionsRegion}-$projectId.cloudfunctions.net/generateReply';
  }

  /// Returns [count] options (one per tone, Chill → Bold) or a single reply at
  /// [tone] when [count] is 1.
  ///
  /// With [tweak], [previous] is rewritten instead (always one reply).
  Future<ReplyBatch> generateReplies({
    required BroMode mode,
    required String context,
    required double tone,
    required AppLanguage language,
    int count = 1,
    bool tips = false,
    String? notes,
    ReplyPrefs prefs = const ReplyPrefs(),
    ReplyTweak? tweak,
    String? previous,
  }) async {
    final headers = <String, String>{};
    if (AppConstants.selfHosted) {
      if (AppConstants.broClientToken.isNotEmpty) headers['X-Bro-Client'] = AppConstants.broClientToken;
    } else {
      try {
        final token = await FirebaseAppCheck.instance.getToken();
        if (token != null) headers['X-Firebase-AppCheck'] = token;
      } catch (e) {
        // The backend rejects requests without a valid token, so surface that
        // as a normal error below rather than crashing here.
        debugPrint('App Check token unavailable: $e');
      }
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: {
          'data': {
            'mode': mode.apiValue,
            'context': context,
            'tone': double.parse(tone.toStringAsFixed(2)),
            'language': language.apiValue,
            'deviceId': _deviceId,
            'count': count,
            'tips': tips,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
            'prefs': prefs.toJson(),
            if (tweak != null) 'tweak': tweak.apiValue,
            if (tweak != null) 'previous': previous,
          },
        },
        options: Options(headers: headers),
      );
      final result = response.data?['result'];
      final options = <ReplyOption>[
        if (result is Map && result['replies'] is List)
          for (final r in result['replies'] as List)
            if (r is Map && r['reply'] is String && (r['reply'] as String).isNotEmpty)
              ReplyOption(
                label: r['label'] is String ? r['label'] as String : toneLabel(tone),
                tone: r['tone'] is num ? (r['tone'] as num).toDouble() : tone,
                text: r['reply'] as String,
                tip: r['tip'] is String ? r['tip'] as String : null,
              ),
      ];
      // Older backends only send `reply`.
      if (options.isEmpty && result is Map && result['reply'] is String && (result['reply'] as String).isNotEmpty) {
        options.add(ReplyOption(label: toneLabel(tone), tone: tone, text: result['reply'] as String));
      }
      if (options.isEmpty) throw const ApiException('Came back empty. Hit regenerate.');
      return ReplyBatch(options, _parseQuota(result is Map ? result['quota'] : null));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  static Quota? _parseQuota(Object? raw) {
    if (raw is! Map || raw['remaining'] is! num || raw['limit'] is! num || raw['resetAt'] is! num) return null;
    return Quota(
      remaining: (raw['remaining'] as num).toInt(),
      limit: (raw['limit'] as num).toInt(),
      resetAt: DateTime.fromMillisecondsSinceEpoch((raw['resetAt'] as num).toInt()),
    );
  }

  ApiException _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      final message = error['message'];
      if (message is String && message.isNotEmpty && error['status'] != 'INTERNAL') {
        return ApiException(message);
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('That took too long. Check your connection and try again.');
      case DioExceptionType.connectionError:
        return const ApiException('No connection. Get some signal and try again.');
      default:
        return const ApiException('Something broke on our side. Try again in a moment.');
    }
  }
}
