import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/current_state.dart';
import '../models/sensor_reading.dart';
import '../models/threshold_event.dart';
import '../models/time_filter.dart';
import 'firebase_service.dart';
import 'current_state_service.dart';
import 'sensor_reading_service.dart';
import 'threshold_event_service.dart';

/// Service principal qui coordonne tous les services de capteurs
class SensorService extends ChangeNotifier {
  final FirebaseService _firebaseService;
  CurrentStateService? _currentStateService;
  SensorReadingService? _sensorReadingService;
  ThresholdEventService? _thresholdEventService;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Cache pour l'état actuel
  CurrentState? _lastKnownState;
  CurrentState? get lastKnownState => _lastKnownState;

  /// Filtre temporel actuel
  TimeFilter _currentTimeFilter = TimeFilter.oneHour;
  TimeFilter get currentTimeFilter => _currentTimeFilter;

  /// État de connexion
  bool get isConnected => _firebaseService.isConnected;

  /// Constructeur
  SensorService() : _firebaseService = FirebaseService() {
    _initializeServices();
  }

  /// Initialise tous les services
  Future<void> _initializeServices() async {
    try {
      // Initialiser le service Firebase
      await _firebaseService.initialize();

      // Initialiser les services spécialisés
      _currentStateService = CurrentStateService(_firebaseService);
      _sensorReadingService = SensorReadingService(_firebaseService);
      _thresholdEventService = ThresholdEventService(_firebaseService);

      // Écouter l'état actuel
      _currentStateService?.stateStream.listen((state) {
        _lastKnownState = state;
        notifyListeners();
      });

      _isInitialized = true;
      notifyListeners();
      debugPrint('✅ All sensor services initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing sensor services: $e');
      // Essayer d'initialiser avec ce qui a fonctionné
      _isInitialized = _currentStateService != null &&
          _sensorReadingService != null &&
          _thresholdEventService != null;
      notifyListeners();
    }
  }

  /// Vérifie si les services sont prêts
  bool _areServicesReady() {
    return _isInitialized &&
        _currentStateService != null &&
        _sensorReadingService != null &&
        _thresholdEventService != null;
  }

  /// Teste la connexion à Firebase
  Future<Map<String, dynamic>?> checkDirectConnection() async {
    try {
      final isConnected = await _firebaseService.checkDirectConnection();

      if (isConnected && _currentStateService != null) {
        // Récupérer l'état actuel
        final state = await _currentStateService!.getCurrentState();

        if (state != null) {
          return {
            'temperature': state.temperature,
            'humidity': state.humidity,
            'last_update': state.lastUpdate.millisecondsSinceEpoch,
            'threshold_high': state.thresholdHigh,
            'threshold_low': state.thresholdLow,
            'is_over_threshold': state.isOverThreshold,
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error checking direct connection: $e');
      return null;
    }
  }

  /// Récupère l'état actuel des capteurs
  Stream<CurrentState?> getCurrentState() {
    if (!_areServicesReady()) {
      // Si les services ne sont pas prêts, retourner un stream vide
      return Stream.value(null);
    }
    return _currentStateService!.stateStream;
  }

  /// Récupère les lectures de capteurs
  Stream<List<SensorReading>> getSensorReadings() {
    if (!_areServicesReady()) {
      // Si les services ne sont pas prêts, retourner un stream avec une liste vide
      return Stream.value([]);
    }
    return _sensorReadingService!.readingsStream;
  }

  /// Récupère les événements de dépassement de seuil
  Stream<List<ThresholdEvent>> getThresholdEvents() {
    if (!_areServicesReady()) {
      // Si les services ne sont pas prêts, retourner un stream avec une liste vide
      return Stream.value([]);
    }
    return _thresholdEventService!.eventsStream;
  }

  /// Modifie le filtre temporel pour les lectures de capteurs
  Future<void> setTimeFilter(TimeFilter filter) async {
    _currentTimeFilter = filter;
    if (_areServicesReady()) {
      await _sensorReadingService!.setTimeFilter(filter);
    }
    notifyListeners();
  }

  /// Met à jour les seuils de température
  Future<void> updateThresholds(
      double lowThreshold, double highThreshold) async {
    if (!_areServicesReady()) {
      debugPrint('❌ Services not initialized, cannot update thresholds');
      return;
    }

    await _currentStateService!.updateThresholds(lowThreshold, highThreshold);

    // Vérifier si la température actuelle dépasse les nouveaux seuils
    final currentState = _currentStateService!.currentState;
    if (currentState != null) {
      // Si la température est hors limites, créer un événement
      if (currentState.temperature > highThreshold) {
        await _thresholdEventService!.createThresholdEvent(
          temperature: currentState.temperature,
          humidity: currentState.humidity,
          eventType: ThresholdEventType.exceeded,
          thresholdHigh: highThreshold,
          thresholdLow: lowThreshold,
        );
      } else if (currentState.temperature < lowThreshold) {
        await _thresholdEventService!.createThresholdEvent(
          temperature: currentState.temperature,
          humidity: currentState.humidity,
          eventType: ThresholdEventType.exceeded,
          thresholdHigh: highThreshold,
          thresholdLow: lowThreshold,
        );
      }
    }
  }

  /// Rafraîchit toutes les données
  Future<void> refreshAllData() async {
    if (!_areServicesReady()) {
      debugPrint('❌ Services not initialized, cannot refresh data');
      return;
    }

    try {
      await Future.wait([
        _currentStateService!.getCurrentState(),
        _sensorReadingService!.getSensorReadings(),
        _thresholdEventService!.getThresholdEvents(),
      ]);

      debugPrint('✅ All data refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing all data: $e');
    }
  }

  @override
  void dispose() {
    _currentStateService?.dispose();
    _sensorReadingService?.dispose();
    _thresholdEventService?.dispose();
    _firebaseService.dispose();
    super.dispose();
  }
}
