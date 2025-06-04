import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Configurations pour Firebase Realtime Database
///
/// Pour Realtime Database, seules deux informations sont essentielles :
/// 1. databaseURL: L'URL de votre base de données Realtime Database
/// 2. apiKey: Votre clé API ou token d'authentification pour accéder à la base
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Pour simplifier, on utilise les mêmes configurations pour toutes les plateformes
    return realtimeDbConfig;
  }

  /// Configuration pour la base de données Firebase Realtime
  ///
  /// ATTENTION: Vérifiez que ces valeurs correspondent à votre projet Firebase
  static const FirebaseOptions realtimeDbConfig = FirebaseOptions(
    // Votre clé API ou token d'authentification
    apiKey: 'aoPGeVFXtvbmbVP3ptRpfnGwxSv1',

    // URL complète de votre base de données Realtime
    databaseURL:
        'https://appliflutteriot-default-rtdb.europe-west1.firebasedatabase.app/',

    // Les champs suivants sont requis par Firebase mais ne sont pas utilisés
    // dans notre application pour Realtime Database
    appId: '1:1234567890:android:1234567890',
    messagingSenderId: '1234567890',
    projectId: 'appliflutteriot',
  );
}
