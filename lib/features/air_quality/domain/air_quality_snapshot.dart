enum AirQualityLevel {
  good,
  moderate,
  unhealthySensitive,
  unhealthy,
  veryUnhealthy,
  hazardous,
}

class PollutantReading {
  const PollutantReading({
    required this.name,
    required this.value,
    required this.unit,
    required this.guideline,
  });

  final String name;
  final double value;
  final String unit;

  /// Valeur guide OMS (même unité) servant d'échelle aux jauges.
  final double guideline;

  double get ratio => guideline <= 0 ? 0 : value / guideline;
}

class AirQualitySnapshot {
  const AirQualitySnapshot({
    required this.city,
    required this.aqi,
    required this.pollutants,
    required this.updatedAt,
  });

  final String city;

  /// Indice US AQI (0–500).
  final int aqi;
  final List<PollutantReading> pollutants;
  final DateTime updatedAt;

  AirQualityLevel get level => airQualityLevelForAqi(aqi);

  PollutantReading? pollutant(String name) {
    for (final p in pollutants) {
      if (p.name == name) return p;
    }
    return null;
  }
}

extension AirQualityLevelLabels on AirQualityLevel {
  String get label => switch (this) {
    AirQualityLevel.good => 'Bon',
    AirQualityLevel.moderate => 'Modéré',
    AirQualityLevel.unhealthySensitive => 'Médiocre',
    AirQualityLevel.unhealthy => 'Mauvais',
    AirQualityLevel.veryUnhealthy => 'Très mauvais',
    AirQualityLevel.hazardous => 'Dangereux',
  };

  String get advice => switch (this) {
    AirQualityLevel.good =>
      "La qualité de l'air est satisfaisante. Idéal pour les activités en extérieur.",
    AirQualityLevel.moderate =>
      'Qualité acceptable. Les personnes très sensibles peuvent limiter les efforts prolongés.',
    AirQualityLevel.unhealthySensitive =>
      'Les personnes sensibles (asthme, enfants, seniors) devraient réduire les efforts en extérieur.',
    AirQualityLevel.unhealthy =>
      'Limitez les activités physiques intenses en extérieur.',
    AirQualityLevel.veryUnhealthy =>
      'Évitez les efforts en extérieur et aérez peu votre logement.',
    AirQualityLevel.hazardous => 'Restez à l’intérieur autant que possible.',
  };

  int get priority => index;
}

AirQualityLevel airQualityLevelForAqi(int aqi) {
  if (aqi <= 50) return AirQualityLevel.good;
  if (aqi <= 100) return AirQualityLevel.moderate;
  if (aqi <= 150) return AirQualityLevel.unhealthySensitive;
  if (aqi <= 200) return AirQualityLevel.unhealthy;
  if (aqi <= 300) return AirQualityLevel.veryUnhealthy;
  return AirQualityLevel.hazardous;
}
