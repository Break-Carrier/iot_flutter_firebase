
/// Type d'événement de seuil
enum ThresholdEventType {
  /// Dépassement de seuil (peut être haut ou bas)
  exceeded,

  /// Retour à la normale
  normal
}

/// Représente un événement de dépassement de seuil
class ThresholdEvent {
  final String? id;
  final double temperature;
  final double humidity;
  final DateTime timestamp;
  final ThresholdEventType eventType;
  final double thresholdHigh;
  final double thresholdLow;

  /// Constructeur pour créer un nouvel événement
  ThresholdEvent({
    this.id,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    required this.eventType,
    required this.thresholdHigh,
    required this.thresholdLow,
  });

  /// Constructeur à partir des données Firebase Realtime Database
  factory ThresholdEvent.fromRealtimeDB(Map<String, dynamic> data,
      [String? key]) {
    ThresholdEventType type;

    // Déterminer le type d'événement
    final eventStr = data['event'] as String;
    if (eventStr == 'threshold_exceeded') {
      type = ThresholdEventType.exceeded;
    } else {
      type = ThresholdEventType.normal;
    }

    return ThresholdEvent(
      id: key,
      temperature: (data['temperature'] as num).toDouble(),
      humidity: (data['humidity'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
      eventType: type,
      thresholdHigh: (data['threshold_high'] as num).toDouble(),
      thresholdLow: (data['threshold_low'] as num).toDouble(),
    );
  }

  /// Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    String eventStr;

    switch (eventType) {
      case ThresholdEventType.exceeded:
        eventStr = 'threshold_exceeded';
        break;
      case ThresholdEventType.normal:
        eventStr = 'threshold_normal';
        break;
    }

    return {
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'event': eventStr,
      'threshold_high': thresholdHigh,
      'threshold_low': thresholdLow,
    };
  }

  /// Déterminer si c'est un dépassement de seuil
  bool get isExceeded => eventType == ThresholdEventType.exceeded;

  /// Déterminer si c'est un retour à la normale
  bool get isNormal => eventType == ThresholdEventType.normal;

  /// Déterminer si la température est au-dessus du seuil haut
  bool get isHighTemperature => temperature > thresholdHigh;

  /// Déterminer si la température est en-dessous du seuil bas
  bool get isLowTemperature => temperature < thresholdLow;

  /// Description de l'événement
  String get description {
    if (isExceeded) {
      if (isHighTemperature) {
        return 'Température élevée: $temperature°C (seuil: $thresholdHigh°C)';
      } else if (isLowTemperature) {
        return 'Température basse: $temperature°C (seuil: $thresholdLow°C)';
      } else {
        return 'Seuil dépassé: $temperature°C';
      }
    } else {
      return 'Retour à la normale: $temperature°C';
    }
  }

  @override
  String toString() {
    return 'ThresholdEvent(type: $eventType, temp: $temperature°C, time: ${timestamp.toIso8601String()})';
  }
}
