
/// Représente une lecture de capteur à un moment spécifique
class SensorReading {
  final double temperature;
  final double humidity;
  final DateTime timestamp;
  final String? id;

  /// Constructeur pour créer une nouvelle lecture
  SensorReading({
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    this.id,
  });

  /// Constructeur à partir des données Firebase Realtime Database
  factory SensorReading.fromRealtimeDB(Map<String, dynamic> data,
      [String? key]) {
    return SensorReading(
      temperature: (data['temperature'] as num).toDouble(),
      humidity: (data['humidity'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
      id: key,
    );
  }

  /// Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return 'SensorReading(temp: $temperature°C, humidity: $humidity%, time: ${timestamp.toIso8601String()})';
  }
}
