abstract final class AppConstants {
  static const String appName = 'BRO PROTOCOL';
  static const String tagline = 'Say less. Say it right.';
  static const String version = '1.0.0';

  /// Where users reach you. Set it per build: --dart-define=SUPPORT_EMAIL=you@yourdomain.com
  static const String supportEmail = String.fromEnvironment('SUPPORT_EMAIL', defaultValue: 'support@example.com');

  /// Bump when the Terms or Privacy Policy change materially: everyone sees
  /// onboarding again and re-accepts.
  static const int termsVersion = 1;

  /// Content is centered at this width on tablets, desktop and the web.
  static const double maxContentWidth = 640;

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

  /// Matches the backend's MAX_NOTES_LENGTH.
  static const int maxNotesLength = 1000;

  /// Matches the backend's MAX_STYLE_LENGTH.
  static const int maxStyleLength = 300;

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
  static const String matches = 'matches';
  static const String saved = 'saved';
  static const String stats = 'stats';
}

abstract final class HiveTypeIds {
  static const int generation = 1;
}
