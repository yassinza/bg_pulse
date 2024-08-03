import 'package:intl/intl.dart';

class GlucoseReading {
  final DateTime timestamp;
  final double value;
  final String trend;

  GlucoseReading({
    required this.timestamp,
    required this.value,
    required this.trend,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    final dateFormat = DateFormat("M/d/yyyy h:mm:ss a");

    return GlucoseReading(
      timestamp: dateFormat.parse(json['Timestamp']),
      value: json['ValueInMgPerDl'].toDouble(),
      trend: _determineTrend(json['TrendArrow']),
    );
  }

  static String _determineTrend(int? trendArrow) {
    switch (trendArrow) {
      case 1:
        return 'rising';
      case 2:
        return 'falling';
      case 3:
        return 'stable';
      default:
        return 'unknown';
    }
  }

  String get emoji => glucoseLevelToEmoji(value);

  String get trendArrow {
    switch (trend) {
      case 'rising':
        return '↑';
      case 'falling':
        return '↓';
      default:
        return '→';
    }
  }
}

String glucoseLevelToEmoji(double level) {
  if (level < 70) {
    return '🔴'; // Low
  } else if (level >= 70 && level <= 180) {
    return '🟢'; // Normal
  } else {
    return '🟠'; // High
  }
}
