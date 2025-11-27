// File generated using FlutterFire CLI.
// NOTE: L'utilisateur devra générer ce fichier avec: flutterfire configure
// Ce fichier est un placeholder

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCJLgJHMGIbi7n0dQy1_EMUZZQIUCNCimE',
    appId: '1:868597908548:web:882bf6a22b8b40c64ae811',
    messagingSenderId: '868597908548',
    projectId: 'notilus-browser',
    authDomain: 'notilus-browser.firebaseapp.com',
    storageBucket: 'notilus-browser.firebasestorage.app',
    measurementId: 'G-K1GL90LBWR',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCmLr0lJm5LMdPm8V7qMLS-V2yi8qIOly4',
    appId: '1:868597908548:ios:d29afd5443de27144ae811',
    messagingSenderId: '868597908548',
    projectId: 'notilus-browser',
    storageBucket: 'notilus-browser.firebasestorage.app',
    iosBundleId: 'com.example.notilus',
  );

}
