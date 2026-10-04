abstract final class AppConstants {
  static const String appName = 'BRO PROTOCOL';
  static const String tagline = 'Say less. Say it right.';
  static const String version = '1.0.0';

  /// Region the `generateReply` Cloud Function is deployed to.
  static const String functionsRegion = 'us-central1';

  /// Optional override, e.g. for the emulator:
  /// `flutter run --dart-define=FUNCTIONS_BASE_URL=http://10.0.2.2:5001/<project-id>/us-central1`
  static const String functionsBaseUrlOverride = String.fromEnvironment('FUNCTIONS_BASE_URL');

  /// Self-hosted (Docker) backend, e.g. `--dart-define=BRO_BACKEND_URL=http://10.0.2.2:8080`.
  /// When set, the app skips Firebase entirely and calls this server instead.
  static const String broBackendUrl = String.fromEnvironment('BRO_BACKEND_URL');

  /// Must match the server's CLIENT_TOKEN when that is set.
  static const String broClientToken = String.fromEnvironment('BRO_CLIENT_TOKEN');

  static bool get selfHosted => broBackendUrl.isNotEmpty;

  static const int historyLimit = 20;
  static const int maxContextLength = 5000;

  static const Duration splashDuration = Duration(milliseconds: 2200);
  static const Duration splashReducedMotionDuration = Duration(milliseconds: 900);

  static const List<String> splashStatus = [
    'Reading the room…',
    'Sharpening the wit…',
    'Protocol engaged.',
  ];
}

abstract final class HiveBoxes {
  static const String history = 'history';
  static const String settings = 'settings';
}

abstract final class HiveTypeIds {
  static const int generation = 1;
}
