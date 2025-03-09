import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/current_state.dart';
import '../utils/map_converter.dart';
import 'firebase_service.dart';

/// Service pour gérer l'état actuel des capteurs
class CurrentStateService extends ChangeNotifier {
  final FirebaseService _firebaseService;

  /// Chemin vers la collection dans Firebase
  static const String _path = 'current_state';

  /// État actuel des capteurs
  CurrentState? _currentState;
  CurrentState? get currentState => _currentState;

  /// Stream controller pour émettre l'état actuel
  final _stateStreamController = StreamController<CurrentState?>.broadcast();
  Stream<CurrentState?> get stateStream => _stateStreamController.stream;

  /// Abonnement au stream Firebase
  StreamSubscription? _stateSubscription;

  /// Constructeur
  CurrentStateService(this._firebaseService) {
    _setupStateListener();
  }

  /// Configure l'écouteur d'état
  void _setupStateListener() {
    try {
      _stateSubscription =
          _firebaseService.getDataStream(_path).listen((event) {
        if (event.snapshot.exists) {
          try {
            // Convertir les données de façon sécurisée
            if (event.snapshot.value is Map) {
              final rawData = event.snapshot.value as Map<Object?, Object?>;
              final Map<String, dynamic> data =
                  MapConverter.convertToStringDynamicMap(rawData);

              _currentState = CurrentState.fromRealtimeDB(data);
              _stateStreamController.add(_currentState);
              notifyListeners();
              debugPrint(
                  '📊 Current state updated: ${_currentState?.temperature}°C, ${_currentState?.humidity}%');
            } else {
              debugPrint('⚠️ Les données reçues ne sont pas au format Map');
              _stateStreamController.add(null);
            }
          } catch (e) {
            debugPrint('❌ Erreur de conversion des données: $e');
            _stateStreamController.addError(e);
          }
        } else {
          debugPrint('⚠️ No current state data available');
          _stateStreamController.add(null);
        }
      }, onError: (error) {
        debugPrint('❌ Error listening to current state: $error');
        _stateStreamController.addError(error);
      });
    } catch (e) {
      debugPrint('❌ Error setting up current state listener: $e');
    }
  }

  /// Récupère l'état actuel une seule fois
  Future<CurrentState?> getCurrentState() async {
    try {
      final data = await _firebaseService.getData(_path);
      if (data != null) {
        _currentState = CurrentState.fromRealtimeDB(data);
        debugPrint(
            '📊 Current state fetched: ${_currentState?.temperature}°C, ${_currentState?.humidity}%');
        return _currentState;
      } else {
        debugPrint('⚠️ No current state data available');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching current state: $e');
      rethrow;
    }
  }

  /// Met à jour les seuils de température
  Future<void> updateThresholds(
      double lowThreshold, double highThreshold) async {
    try {
      if (lowThreshold >= highThreshold) {
        throw ArgumentError('Le seuil bas doit être inférieur au seuil haut');
      }

      // Vérifier si la température actuelle dépasse les nouveaux seuils
      bool isOverThreshold = false;
      if (_currentState != null) {
        isOverThreshold = _currentState!.temperature > highThreshold ||
            _currentState!.temperature < lowThreshold;
      }

      // Préparer les données à mettre à jour
      final updateData = {
        'threshold_low': lowThreshold,
        'threshold_high': highThreshold,
        'last_update': DateTime.now().millisecondsSinceEpoch,
        'is_over_threshold': isOverThreshold,
      };

      await _firebaseService.updateData(_path, updateData);

      debugPrint(
          '✅ Thresholds updated: low=$lowThreshold, high=$highThreshold, isOverThreshold=$isOverThreshold');

      // Actualiser l'état actuel
      await getCurrentState();
    } catch (e) {
      debugPrint('❌ Error updating thresholds: $e');
      rethrow;
    }
  }

  /// Vérifie si la température actuelle dépasse les seuils
  bool isTemperatureOverThreshold() {
    if (_currentState == null) return false;

    return _currentState!.isLowTemperature || _currentState!.isHighTemperature;
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _stateStreamController.close();
    super.dispose();
  }
}
