// File generated manually from Firebase CLI SDK configs.
// flutterfire configure could not run due to org-level permissions.
//
// Project: astra-488209

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAJZQzFlaweePDoOoOiGMm6pDk6QrrBRm4',
    appId: '1:612024885391:web:2a8ef274772a62537790fa',
    messagingSenderId: '612024885391',
    projectId: 'astra-488209',
    authDomain: 'astra-488209.firebaseapp.com',
    storageBucket: 'astra-488209.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDZxp6dr-a_0tSufbF5C2egEki03iQhBrU',
    appId: '1:612024885391:android:2117f4a0a01ec0597790fa',
    messagingSenderId: '612024885391',
    projectId: 'astra-488209',
    storageBucket: 'astra-488209.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCk5e16xYEHYGs4E_BYO86PxqRbc4ZoChE',
    appId: '1:612024885391:ios:29d64d814b2484817790fa',
    messagingSenderId: '612024885391',
    projectId: 'astra-488209',
    storageBucket: 'astra-488209.firebasestorage.app',
    iosBundleId: 'com.skynergroup.stokvelmanager.stokvelManager',
  );
}
