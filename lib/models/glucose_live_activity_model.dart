import 'glucose_reading.dart';

class GlucoseLiveActivityModel {
  final double value;
  final String trend;
  final DateTime timestamp;
  final String emoji;
  final String trendArrow;
  final List<double> readings; //last 5 readings

  GlucoseLiveActivityModel({
    required this.value,
    required this.trend,
    required this.timestamp,
    required this.emoji,
    required this.trendArrow,
    required this.readings,
  });

  factory GlucoseLiveActivityModel.fromReadings(List<GlucoseReading> readings) {
    int start = readings.length >= 5 ? readings.length - 5 : 0;
    return GlucoseLiveActivityModel(
      value: readings.last.value,
      trend: readings.last.trend,
      timestamp: readings.last.timestamp,
      emoji: readings.last.emoji,
      trendArrow: readings.last.trendArrow,
      readings: readings.sublist(start).map((reading) => reading.value).toList(),
    );
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
      readings: readings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'trend': trend,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'emoji': emoji,
      'trendArrow': trendArrow,
      'readings': readings.map((reading) => reading).toList(),
    };
  }
}
