enum AirQualityLevel { good, moderate, unhealthy, veryUnhealthy, hazardous }

class PollutantReading {
  const PollutantReading({
    required this.name,
    required this.value,
    required this.unit,
  });

  final String name;
  final double value;
  final String unit;
}

class AirQualitySnapshot {
  const AirQualitySnapshot({
    required this.city,
    required this.aqi,
    required this.level,
    required this.pollutants,
    required this.updatedAt,
  });

  final String city;
  final int aqi;
  final AirQualityLevel level;
  final List<PollutantReading> pollutants;
  final DateTime updatedAt;
}

extension AirQualityLevelLabels on AirQualityLevel {
  String get label {
    switch (this) {
      case AirQualityLevel.good:
        return 'Bon';
      case AirQualityLevel.moderate:
        return 'Modéré';
      case AirQualityLevel.unhealthy:
        return 'Mauvais';
      case AirQualityLevel.veryUnhealthy:
        return 'Très mauvais';
      case AirQualityLevel.hazardous:
        return 'Dangereux';
    }
  }

  int get priority => index;
}

AirQualityLevel airQualityLevelForAqi(int aqi) {
  if (aqi <= 50) return AirQualityLevel.good;
  if (aqi <= 100) return AirQualityLevel.moderate;
  if (aqi <= 150) return AirQualityLevel.unhealthy;
  if (aqi <= 200) return AirQualityLevel.veryUnhealthy;
  return AirQualityLevel.hazardous;
}
