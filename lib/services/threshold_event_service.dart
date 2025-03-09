import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/threshold_event.dart';
import '../utils/map_converter.dart';
import 'firebase_service.dart';

/// Service pour gérer les événements de dépassement de seuil
class ThresholdEventService extends ChangeNotifier {
  final FirebaseService _firebaseService;

  /// Chemin vers la collection dans Firebase
  static const String _path = 'threshold_events';

  /// Liste des événements de dépassement de seuil
  List<ThresholdEvent> _events = [];
  List<ThresholdEvent> get events => _events;

  /// Stream controller pour émettre les événements
  final _eventsStreamController =
      StreamController<List<ThresholdEvent>>.broadcast();
  Stream<List<ThresholdEvent>> get eventsStream =>
      _eventsStreamController.stream;

  /// Abonnement au stream Firebase
  StreamSubscription? _eventsSubscription;

  /// Limite du nombre d'événements à récupérer
  final int _limit;

  /// Constructeur
  ThresholdEventService(this._firebaseService, {int limit = 50})
      : _limit = limit {
    _setupEventsListener();
  }

  /// Configure l'écouteur d'événements
  void _setupEventsListener() {
    try {
      _eventsSubscription = _firebaseService
          .getLatestEntriesStream(_path, _limit)
          .listen((event) {
        if (event.snapshot.exists) {
          try {
            // Convertir les données de façon sécurisée
            if (event.snapshot.value is Map) {
              final rawData = event.snapshot.value as Map<Object?, Object?>;
              final Map<String, dynamic> data = MapConverter.convertToStringDynamicMap(rawData);
              
              _processEventsData(data);
            } else {
              debugPrint('⚠️ Les données reçues ne sont pas au format Map');
              _events = [];
              _eventsStreamController.add(_events);
              notifyListeners();
            }
          } catch (e) {
            debugPrint('❌ Erreur de conversion des données: $e');
            _eventsStreamController.addError(e);
          }
        } else {
          debugPrint('⚠️ No threshold events data available');
          _events = [];
          _eventsStreamController.add(_events);
          notifyListeners();
        }
      }, onError: (error) {
        debugPrint('❌ Error listening to threshold events: $error');
        _eventsStreamController.addError(error);
      });
    } catch (e) {
      debugPrint('❌ Error setting up threshold events listener: $e');
    }
  }

  /// Traite les données d'événements reçues de Firebase
  void _processEventsData(Map<String, dynamic> data) {
    try {
      _events = [];

      // Convertir chaque entrée en objet ThresholdEvent
      data.forEach((key, value) {
        try {
          final event =
              ThresholdEvent.fromRealtimeDB(value as Map<String, dynamic>, key);
          _events.add(event);
        } catch (e) {
          debugPrint('⚠️ Error parsing threshold event: $e');
        }
      });

      // Trier par timestamp (plus récent en premier)
      _events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _eventsStreamController.add(_events);
      notifyListeners();

      debugPrint('🚨 ${_events.length} threshold events updated');
    } catch (e) {
      debugPrint('❌ Error processing threshold events data: $e');
    }
  }

  /// Récupère les événements une seule fois
  Future<List<ThresholdEvent>> getThresholdEvents() async {
    try {
      final data = await _firebaseService.getLatestEntries(_path, _limit);

      if (data != null) {
        _processEventsData(data);
        return _events;
      } else {
        debugPrint('⚠️ No threshold events data available');
        _events = [];
        _eventsStreamController.add(_events);
        notifyListeners();
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching threshold events: $e');
      rethrow;
    }
  }

  /// Crée un nouvel événement de dépassement de seuil
  Future<String?> createThresholdEvent({
    required double temperature,
    required double humidity,
    required ThresholdEventType eventType,
    required double thresholdHigh,
    required double thresholdLow,
  }) async {
    try {
      final event = ThresholdEvent(
        temperature: temperature,
        humidity: humidity,
        timestamp: DateTime.now(),
        eventType: eventType,
        thresholdHigh: thresholdHigh,
        thresholdLow: thresholdLow,
      );

      final eventData = event.toMap();
      final eventId = await _firebaseService.pushData(_path, eventData);

      debugPrint('✅ New threshold event created with ID: $eventId');

      // Actualiser la liste des événements
      await getThresholdEvents();

      return eventId;
    } catch (e) {
      debugPrint('❌ Error creating threshold event: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _eventsStreamController.close();
    super.dispose();
  }
}
