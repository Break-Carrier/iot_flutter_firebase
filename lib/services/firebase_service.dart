import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../firebase_options.dart';

/// Service de base pour la communication avec Firebase Realtime Database
class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Référence à la base de données
  DatabaseReference get databaseRef => _database.ref();

  /// Indique si le service est connecté
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Écouteur d'état de connexion
  StreamSubscription? _connectedSubscription;

  /// Vérifie si la configuration minimale est valide
  bool _checkMinimalConfig() {
    final options = DefaultFirebaseOptions.currentPlatform;

    // Pour Realtime Database, nous avons besoin au minimum de l'URL de la base
    // et d'une clé d'API ou token d'authentification
    final hasValidDbUrl = options.databaseURL?.isNotEmpty ?? false;
    final hasValidAuth = options.apiKey.isNotEmpty;

    if (!hasValidDbUrl) {
      debugPrint('⚠️ ERREUR: URL de base de données manquante ou invalide!');
      return false;
    }

    if (!hasValidAuth) {
      debugPrint('⚠️ ERREUR: Clé API manquante!');
      return false;
    }

    return true;
  }

  /// Initialise le service et écoute les changements de connectivité
  Future<void> initialize() async {
    try {
      // Vérifier la configuration minimale
      if (!_checkMinimalConfig()) {
        throw Exception(
            'Configuration Firebase minimale invalide. Au minimum, databaseURL et apiKey sont requis.');
      }

      // Définir l'URL de la base de données
      final dbUrl = DefaultFirebaseOptions.currentPlatform.databaseURL;
      if (dbUrl?.isNotEmpty ?? false) {
        debugPrint('📊 Utilisation de l\'URL de base de données: $dbUrl');
        _database.databaseURL = dbUrl;
      }

      // Écouter l'état de connectivité à Firebase
      _connectedSubscription =
          _database.ref('.info/connected').onValue.listen((event) {
        _isConnected = event.snapshot.value as bool? ?? false;
        debugPrint(
            '🔌 Firebase Connectivity: ${_isConnected ? 'Connected' : 'Disconnected'}');
      }, onError: (error) {
        debugPrint('❌ Erreur de connexion Firebase: $error');
        _isConnected = false;
      });

      // Configurer la persistence (seulement pour les plateformes non-web)
      if (!kIsWeb) {
        _database.setPersistenceEnabled(true);
        _database.setPersistenceCacheSizeBytes(10000000); // ~10MB
      }

      debugPrint('✅ Service Firebase initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur d\'initialisation du service Firebase: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Écrit des données à un chemin spécifique
  Future<void> setData(String path, Map<String, dynamic> data) async {
    try {
      await _database.ref(path).set(data);
      debugPrint('✅ Données définies à $path');
    } catch (e) {
      debugPrint('❌ Erreur lors de la définition des données à $path: $e');
      rethrow;
    }
  }

  /// Met à jour des données à un chemin spécifique
  Future<void> updateData(String path, Map<String, dynamic> data) async {
    try {
      await _database.ref(path).update(data);
      debugPrint('✅ Données mises à jour à $path');
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour des données à $path: $e');
      rethrow;
    }
  }

  /// Récupère des données une fois depuis un chemin spécifique
  Future<Map<String, dynamic>?> getData(String path) async {
    try {
      final snapshot = await _database.ref(path).get();
      if (snapshot.exists) {
        return snapshot.value as Map<String, dynamic>?;
      } else {
        debugPrint('⚠️ Aucune donnée disponible à $path');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des données de $path: $e');
      rethrow;
    }
  }

  /// Écoute les changements à un chemin spécifique
  Stream<DatabaseEvent> getDataStream(String path) {
    return _database.ref(path).onValue;
  }

  /// Récupère les dernières entrées d'une collection limitée à un nombre spécifique
  Future<Map<String, dynamic>?> getLatestEntries(String path, int limit) async {
    try {
      final query =
          _database.ref(path).orderByChild('timestamp').limitToLast(limit);

      final snapshot = await query.get();
      if (snapshot.exists) {
        return snapshot.value as Map<String, dynamic>?;
      } else {
        debugPrint('⚠️ Aucune donnée disponible à $path');
        return null;
      }
    } catch (e) {
      debugPrint(
          '❌ Erreur lors de la récupération des dernières entrées de $path: $e');
      rethrow;
    }
  }

  /// Écoute les dernières entrées d'une collection limitée à un nombre spécifique
  Stream<DatabaseEvent> getLatestEntriesStream(String path, int limit) {
    final query =
        _database.ref(path).orderByChild('timestamp').limitToLast(limit);

    return query.onValue;
  }

  /// Ajoute une nouvelle entrée à une collection et retourne la clé générée
  Future<String?> pushData(String path, Map<String, dynamic> data) async {
    try {
      final newRef = _database.ref(path).push();
      await newRef.set(data);
      debugPrint('✅ Données ajoutées à $path avec la clé ${newRef.key}');
      return newRef.key;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout de données à $path: $e');
      rethrow;
    }
  }

  /// Supprime des données à un chemin spécifique
  Future<void> deleteData(String path) async {
    try {
      await _database.ref(path).remove();
      debugPrint('✅ Données supprimées à $path');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression des données à $path: $e');
      rethrow;
    }
  }

  /// Vérifie la connectivité directe à Firebase
  Future<bool> checkDirectConnection() async {
    try {
      final ref = _database.ref('.info/connected');
      final snapshot = await ref.get();
      final isConnected = snapshot.value as bool? ?? false;
      debugPrint(
          '🔍 Vérification de connexion directe: ${isConnected ? 'Connecté' : 'Déconnecté'}');
      return isConnected;
    } catch (e) {
      debugPrint(
          '❌ Erreur lors de la vérification de la connexion directe: $e');
      return false;
    }
  }

  /// Libère les ressources
  void dispose() {
    _connectedSubscription?.cancel();
    debugPrint('🧹 Service Firebase libéré');
  }
}
