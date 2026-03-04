// File generated manually from GoogleService-Info.plist + google-services.json
// Firebase Phone Auth 전용 (로그인은 Supabase Auth)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions: unsupported platform $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC2tuVZs3vzrbrWABNMim5l99utaj6I24o',
    appId: '1:63795654583:ios:5cd41b6262339edfbf8232',
    messagingSenderId: '63795654583',
    projectId: 'momo-app-1561a',
    storageBucket: 'momo-app-1561a.firebasestorage.app',
    iosBundleId: 'com.dropdown.momo',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvMzeixfRA48aglH_PDjt2VVrm3w8sLD0',
    appId: '1:63795654583:android:54d4408e34e0e9bfbf8232',
    messagingSenderId: '63795654583',
    projectId: 'momo-app-1561a',
    storageBucket: 'momo-app-1561a.firebasestorage.app',
  );
}
