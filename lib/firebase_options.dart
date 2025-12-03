import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB4HjxBIWSY9V7hEEuy3yyHXH88uD7Eh4o',
    appId: '1:650567527082:android:0ab828eea9c005296a3ed3',
    messagingSenderId: '650567527082',
    projectId: 'firstapp-368d1',
    databaseURL: 'https://firstapp-368d1-default-rtdb.firebaseio.com',
    storageBucket: 'firstapp-368d1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDkL2keZXBbZPIV7ismLyUjX3VEWoE4o0w',
    appId: '1:650567527082:ios:8e10249a538e3ca26a3ed3',
    messagingSenderId: '650567527082',
    projectId: 'firstapp-368d1',
    databaseURL: 'https://firstapp-368d1-default-rtdb.firebaseio.com',
    storageBucket: 'firstapp-368d1.firebasestorage.app',
    iosBundleId: 'com.example.personalityTest',
  );
}
