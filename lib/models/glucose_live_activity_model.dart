import 'glucose_reading.dart';

class GlucoseLiveActivityModel {
  final double value;
  final String trend;
  final DateTime timestamp;
  final String emoji;
  final String trendArrow;

  GlucoseLiveActivityModel({
    required this.value,
    required this.trend,
    required this.timestamp,
    required this.emoji,
    required this.trendArrow,
  });

  factory GlucoseLiveActivityModel.fromReading(GlucoseReading reading) {
    return GlucoseLiveActivityModel(
      value: reading.value,
      trend: reading.trend,
      timestamp: reading.timestamp,
      emoji: reading.emoji,
      trendArrow: reading.trendArrow,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'trend': trend,
      'timestamp': timestamp.toIso8601String(),
      'emoji': emoji,
      'trendArrow': trendArrow,
    };
  }

  GlucoseLiveActivityModel copyWith({
    double? value,
    String? trend,
    DateTime? timestamp,
    String? emoji,
    String? trendArrow,
  }) {
    return GlucoseLiveActivityModel(
      value: value ?? this.value,
      trend: trend ?? this.trend,
      timestamp: timestamp ?? this.timestamp,
      emoji: emoji ?? this.emoji,
      trendArrow: trendArrow ?? this.trendArrow,
    );
  }
}