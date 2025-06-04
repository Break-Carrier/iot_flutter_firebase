import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return realtimeDbConfig;
  }

  static const FirebaseOptions realtimeDbConfig = FirebaseOptions(

    apiKey: 'aoPGeVFXtvbmbVP3ptRpfnGwxSv1',

    databaseURL:
        'https://appliflutteriot-default-rtdb.europe-west1.firebasedatabase.app/',

    appId: '1:1234567890:android:1234567890',
    messagingSenderId: '1234567890',
    projectId: 'appliflutteriot',
  );
}
