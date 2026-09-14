// File generated manually from google-services.json / GoogleService-Info.plist.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — '
        'run `flutterfire configure` if you need web support.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        // Same Firebase iOS app is fine for local macOS runs with matching bundle id.
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDA_n4M27LdJwEi5wWlSrvXl4czpACRRPc',
    appId: '1:1029954504426:android:c519df156851f715b23993',
    messagingSenderId: '1029954504426',
    projectId: 'my-love-bc018',
    storageBucket: 'my-love-bc018.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCWtmkqz8WGkIi-UMQ5dl6Di0GkeWPmyn8',
    appId: '1:1029954504426:ios:8f4987d676b3fcf2b23993',
    messagingSenderId: '1029954504426',
    projectId: 'my-love-bc018',
    storageBucket: 'my-love-bc018.firebasestorage.app',
    iosBundleId: 'com.couple.ours',
  );
}
