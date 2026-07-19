import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Build-safe Firebase options.
///
/// Replace this file by running `flutterfire configure` for a real Firebase
/// project. Until then the app uses demo services so Android builds and local
/// reviews do not crash because credentials are missing.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_FIREBASE_API_KEY',
    appId: 'REPLACE_WITH_YOUR_FIREBASE_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_YOUR_STORAGE_BUCKET',
  );

  static bool get isConfigured {
    return !_isPlaceholder(android.apiKey) &&
        !_isPlaceholder(android.appId) &&
        !_isPlaceholder(android.messagingSenderId) &&
        !_isPlaceholder(android.projectId);
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not configured for this Android-focused project.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase options are only configured for Android.',
        );
    }
  }

  static bool _isPlaceholder(String value) {
    return value.isEmpty || value.startsWith('REPLACE_WITH_');
  }
}
