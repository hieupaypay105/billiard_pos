import 'package:anholding_app/firebase_options.dart';
import 'package:anholding_app/src/core/utils/logger.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Ensures the default Firebase app exists.
///
/// Checking whether the app list is empty is not reliable when native code or
/// another isolate already configured the default app — initialization then
/// throws a duplicate-app error. Secondary isolates (e.g. FCM background) always
/// start with an empty Dart-side app list while native may already hold the default.
Future<void> ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

/// Activates App Check after [ensureFirebaseInitialized].
///
/// Debug/profile: debug providers (simulator / emulator — register the debug token
/// in Firebase Console → App Check → Manage debug tokens).
/// Release: Play Integrity (Android) and App Attest with Device Check fallback (Apple).
Future<void> ensureAppCheckActivated() async {
  const androidProvider = kDebugMode
      ? AndroidProvider.debug
      : AndroidProvider.playIntegrity;
  const appleProvider = kDebugMode
      ? AppleProvider.debug
      : AppleProvider.appAttestWithDeviceCheckFallback;

  await FirebaseAppCheck.instance.activate(
    androidProvider: androidProvider,
    appleProvider: appleProvider,
  );
}

/// Logs the resolved default Firebase app in debug/profile to spot project mismatch fast.
void logFirebaseConfiguration() {
  if (kReleaseMode || Firebase.apps.isEmpty) return;

  final options = Firebase.app().options;
  logger.i(
    'Firebase ready: '
    'projectId=${options.projectId}, '
    'appId=${options.appId}, '
    'senderId=${options.messagingSenderId}, '
    'iosBundleId=${options.iosBundleId ?? '-'}',
  );
}
