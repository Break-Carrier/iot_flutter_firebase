import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sensor_reading.dart';
import '../models/time_filter.dart';
import '../utils/map_converter.dart';
import 'firebase_service.dart';

/// Service pour gérer les lectures de capteurs
class SensorReadingService extends ChangeNotifier {
  final FirebaseService _firebaseService;

  /// Chemin vers la collection dans Firebase
  static const String _path = 'sensor_readings';

  /// Filtre temporel actuel
  TimeFilter _timeFilter = TimeFilter.oneHour;
  TimeFilter get timeFilter => _timeFilter;

  /// Liste des lectures de capteurs
  List<SensorReading> _readings = [];
  List<SensorReading> get readings => _readings;

  /// Stream controller pour émettre les lectures de capteurs
  final _readingsStreamController =
      StreamController<List<SensorReading>>.broadcast();
  Stream<List<SensorReading>> get readingsStream =>
      _readingsStreamController.stream;

  /// Abonnement au stream Firebase
  StreamSubscription? _readingsSubscription;

  /// Constructeur
  SensorReadingService(this._firebaseService) {
    _setupReadingsListener();
  }

  /// Configure l'écouteur de lectures
  void _setupReadingsListener() {
    try {
      // Nombre de lectures à récupérer en fonction du filtre temporel
      // Plus le filtre est grand, plus nous avons besoin de données
      int limit = _getLimitForTimeFilter(_timeFilter);

      _readingsSubscription =
          _firebaseService.getLatestEntriesStream(_path, limit).listen((event) {
        if (event.snapshot.exists) {
          try {
            // Convertir les données de façon sécurisée
            if (event.snapshot.value is Map) {
              final rawData = event.snapshot.value as Map<Object?, Object?>;
              final Map<String, dynamic> data = MapConverter.convertToStringDynamicMap(rawData);
              
              _processReadingsData(data);
            } else {
              debugPrint('⚠️ Les données reçues ne sont pas au format Map');
              _readings = [];
              _readingsStreamController.add(_readings);
              notifyListeners();
            }
          } catch (e) {
            debugPrint('❌ Erreur de conversion des données: $e');
            _readingsStreamController.addError(e);
          }
        } else {
          debugPrint('⚠️ No sensor readings data available');
          _readings = [];
          _readingsStreamController.add(_readings);
          notifyListeners();
        }
      }, onError: (error) {
        debugPrint('❌ Error listening to sensor readings: $error');
        _readingsStreamController.addError(error);
      });
    } catch (e) {
      debugPrint('❌ Error setting up sensor readings listener: $e');
    }
  }

  /// Traite les données de lectures reçues de Firebase
  void _processReadingsData(Map<String, dynamic> data) {
    try {
      _readings = [];

      // Convertir chaque entrée en objet SensorReading
      data.forEach((key, value) {
        try {
          final reading =
              SensorReading.fromRealtimeDB(value as Map<String, dynamic>, key);
          _readings.add(reading);
        } catch (e) {
          debugPrint('⚠️ Error parsing sensor reading: $e');
        }
      });

      // Trier par timestamp (plus récent en premier)
      _readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Filtrer par le filtre temporel actuel
      _filterReadingsByTime();

      _readingsStreamController.add(_readings);
      notifyListeners();

      debugPrint('📊 ${_readings.length} sensor readings updated');
    } catch (e) {
      debugPrint('❌ Error processing sensor readings data: $e');
    }
  }

  /// Filtre les lectures par le filtre temporel actuel
  void _filterReadingsByTime() {
    final cutoffTime = _timeFilter.getStartDate();
    _readings = _readings
        .where((reading) => reading.timestamp.isAfter(cutoffTime))
        .toList();
  }

  /// Détermine le nombre de lectures à récupérer en fonction du filtre temporel
  int _getLimitForTimeFilter(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.thirtyMinutes:
        return 30; // Environ une lecture toutes les minutes
      case TimeFilter.oneHour:
        return 60; // Environ une lecture toutes les minutes
      case TimeFilter.threeHours:
        return 90; // Environ une lecture toutes les 2 minutes
      case TimeFilter.sixHours:
        return 120; // Environ une lecture toutes les 3 minutes
      case TimeFilter.twelveHours:
        return 180; // Environ une lecture toutes les 4 minutes
      case TimeFilter.oneDay:
        return 288; // Environ une lecture toutes les 5 minutes
      case TimeFilter.oneWeek:
        return 336; // Environ une lecture toutes les 30 minutes
      case TimeFilter.oneMonth:
        return 720; // Environ une lecture toutes les heures
    }
  }

  /// Récupère les lectures une seule fois
  Future<List<SensorReading>> getSensorReadings() async {
    try {
      int limit = _getLimitForTimeFilter(_timeFilter);
      final data = await _firebaseService.getLatestEntries(_path, limit);

      if (data != null) {
        _processReadingsData(data);
        return _readings;
      } else {
        debugPrint('⚠️ No sensor readings data available');
        _readings = [];
        _readingsStreamController.add(_readings);
        notifyListeners();
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching sensor readings: $e');
      rethrow;
    }
  }

  /// Change le filtre temporel et actualise les données
  Future<void> setTimeFilter(TimeFilter filter) async {
    if (_timeFilter != filter) {
      _timeFilter = filter;

      // Annuler l'abonnement actuel et en créer un nouveau avec la nouvelle limite
      await _readingsSubscription?.cancel();
      _setupReadingsListener();

      // Récupérer les données avec le nouveau filtre
      await getSensorReadings();

      notifyListeners();
      debugPrint('⏱️ Time filter changed to ${filter.displayName}');
    }
  }

  @override
  void dispose() {
    _readingsSubscription?.cancel();
    _readingsStreamController.close();
    super.dispose();
  }
}
