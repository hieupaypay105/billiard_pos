// File generated manually from google-services.json & GoogleService-Info.plist.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform is not configured for this project.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBTxYNqqrGlKOd2QwEqqo_KTF6izxY4VNc',
    appId: '1:123770882118:android:ee8f23bf5782a82c112247',
    messagingSenderId: '123770882118',
    projectId: 'an-holdings-crm-app',
    storageBucket: 'an-holdings-crm-app.firebasestorage.app',
  );

  /// Must match `ios/Runner/GoogleService-Info.plist` exactly.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC1WolSBGM4T6-F5I9Sm185eHGj7YtesZ8',
    appId: '1:123770882118:ios:237e771d2b539381112247',
    messagingSenderId: '123770882118',
    projectId: 'an-holdings-crm-app',
    storageBucket: 'an-holdings-crm-app.firebasestorage.app',
    iosBundleId: 'com.anholding.app',
    iosClientId:
        '123770882118-vf3021nuqlhjfpvt6jhh3f04at6cnuh5.apps.googleusercontent.com',
    androidClientId:
        '123770882118-27kbihdm4ihv5fefqqjifnapt4oln4db.apps.googleusercontent.com',
  );
}
