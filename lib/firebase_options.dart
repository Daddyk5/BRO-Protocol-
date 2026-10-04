// Stand-in so the app compiles before Firebase is set up. It is only used on
// the Firebase backend path; Docker builds (--dart-define=BRO_BACKEND_URL=...)
// never call it.
//
// Running `flutterfire configure` overwrites this file with your project's
// real options.
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase is not configured. Run `flutterfire configure`, or build with '
        '--dart-define=BRO_BACKEND_URL=<your Docker backend> to use the self-hosted server.',
      );
}
