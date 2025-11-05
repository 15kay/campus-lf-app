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
        return macos;
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
    apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyDGxIcoN4M2YO2Nc-gXhIJqiXVzp1e_0Y4'),
    appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: "1:395030362083:web:5b7dc6a44781ee06d292d6"),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: "395030362083"),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'wsucampuslf'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: 'wsucampuslf.firebaseapp.com'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'wsucampuslf.appspot.com'),
    measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: "G-67FLXZLXWF"),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: 'AIzaSyDGxIcoN4M2YO2Nc-gXhIJqiXVzp1e_0Y4'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '1:395030362083:android:demo'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '395030362083'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'wsucampuslf'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'wsucampuslf.appspot.com'),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: 'AIzaSyDGxIcoN4M2YO2Nc-gXhIJqiXVzp1e_0Y4'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '1:395030362083:ios:demo'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '395030362083'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'wsucampuslf'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'wsucampuslf.appspot.com'),
    iosBundleId: String.fromEnvironment('IOS_BUNDLE_ID', defaultValue: 'com.wsu.campuslf'),
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_MACOS_API_KEY', defaultValue: 'AIzaSyDGxIcoN4M2YO2Nc-gXhIJqiXVzp1e_0Y4'),
    appId: String.fromEnvironment('FIREBASE_MACOS_APP_ID', defaultValue: '1:395030362083:macos:demo'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '395030362083'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'wsucampuslf'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'wsucampuslf.appspot.com'),
    iosBundleId: String.fromEnvironment('MACOS_BUNDLE_ID', defaultValue: 'com.wsu.campuslf'),
  );
}