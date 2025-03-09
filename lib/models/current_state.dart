
/// Représente l'état actuel des capteurs IoT
class CurrentState {
  final double temperature;
  final double humidity;
  final double thresholdLow;
  final double thresholdHigh;
  final DateTime lastUpdate;
  final bool isOverThreshold;

  /// Constructeur pour créer un nouvel état
  CurrentState({
    required this.temperature,
    required this.humidity,
    required this.thresholdLow,
    required this.thresholdHigh,
    required this.lastUpdate,
    required this.isOverThreshold,
  });

  /// Constructeur à partir des données Firebase Realtime Database
  factory CurrentState.fromRealtimeDB(Map<String, dynamic> data) {
    return CurrentState(
      temperature: (data['temperature'] as num).toDouble(),
      humidity: (data['humidity'] as num).toDouble(),
      thresholdLow: (data['threshold_low'] as num).toDouble(),
      thresholdHigh: (data['threshold_high'] as num).toDouble(),
      lastUpdate:
          DateTime.fromMillisecondsSinceEpoch(data['last_update'] as int),
      isOverThreshold: data['is_over_threshold'] as bool,
    );
  }

  /// Déterminer si la température est dans la plage normale
  bool get isNormalTemperature =>
      temperature >= thresholdLow && temperature <= thresholdHigh;

  /// Déterminer si la température est basse
  bool get isLowTemperature => temperature < thresholdLow;

  /// Déterminer si la température est élevée
  bool get isHighTemperature => temperature > thresholdHigh;

  /// Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'threshold_low': thresholdLow,
      'threshold_high': thresholdHigh,
      'last_update': lastUpdate.millisecondsSinceEpoch,
      'is_over_threshold': isOverThreshold,
    };
  }

  @override
  String toString() {
    return 'CurrentState(temp: $temperature°C, humidity: $humidity%, thresholdLow: $thresholdLow, thresholdHigh: $thresholdHigh)';
  }
}
