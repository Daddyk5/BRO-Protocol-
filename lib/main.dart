import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'features/history/data/generation.dart';
import 'features/status/status_screens.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // With BRO_BACKEND_URL set (Docker backend) Firebase isn't used at all.
  if (!AppConstants.selfHosted) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      // Debug builds print a debug token to logcat / the Xcode console; register
      // it in Firebase Console → App Check → Manage debug tokens.
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    } catch (error) {
      // A friendly screen instead of a blank one when the backend isn't set up.
      debugPrint('Startup failed: $error');
      runApp(SetupErrorApp(error: error));
      return;
    }
  }

  await Hive.initFlutter();
  Hive.registerAdapter(GenerationAdapter());
  await Hive.openBox<Generation>(HiveBoxes.history);
  await Hive.openBox<dynamic>(HiveBoxes.settings);
  await Hive.openBox<dynamic>(HiveBoxes.matches);
  await Hive.openBox<dynamic>(HiveBoxes.saved);
  await Hive.openBox<dynamic>(HiveBoxes.stats);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: BroApp()));
}
