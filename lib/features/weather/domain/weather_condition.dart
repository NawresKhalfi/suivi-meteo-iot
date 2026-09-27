import '../../../core/widgets/weather_icon.dart';

enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  showers,
  freezingRain,
  snow,
  thunderstorm,
}

enum PrecipitationType { none, rain, snow, ice }

/// Traduit un code météo WMO (Open-Meteo) en condition.
WeatherCondition conditionFromWmo(int code) {
  if (code == 0) return WeatherCondition.clear;
  if (code <= 2) return WeatherCondition.partlyCloudy;
  if (code == 3) return WeatherCondition.cloudy;
  if (code == 45 || code == 48) return WeatherCondition.fog;
  if (code >= 51 && code <= 55) return WeatherCondition.drizzle;
  if (code == 56 || code == 57 || code == 66 || code == 67) {
    return WeatherCondition.freezingRain;
  }
  if (code >= 61 && code <= 65) return WeatherCondition.rain;
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return WeatherCondition.snow;
  }
  if (code >= 80 && code <= 82) return WeatherCondition.showers;
  if (code >= 95) return WeatherCondition.thunderstorm;
  return WeatherCondition.cloudy;
}

extension WeatherConditionX on WeatherCondition {
  /// Libellé court (listes horaires).
  String label({bool isDay = true}) => switch (this) {
    WeatherCondition.clear => isDay ? 'Ciel dégagé' : 'Nuit claire',
    WeatherCondition.partlyCloudy => isDay ? 'Éclaircies' : 'Nuit nuageuse',
    WeatherCondition.cloudy => 'Nuageux',
    WeatherCondition.fog => 'Brouillard',
    WeatherCondition.drizzle => 'Bruine',
    WeatherCondition.rain => 'Pluie',
    WeatherCondition.showers => 'Averses',
    WeatherCondition.freezingRain => 'Pluie verglaçante',
    WeatherCondition.snow => 'Neige',
    WeatherCondition.thunderstorm => 'Orages',
  };

  /// Description longue (bandeau d'accueil).
  String description({bool isDay = true}) => switch (this) {
    WeatherCondition.clear =>
      isDay ? 'Grand soleil, ciel dégagé' : 'Nuit claire et étoilée',
    WeatherCondition.partlyCloudy => "Alternance de nuages et d'éclaircies",
    WeatherCondition.cloudy => 'Ciel couvert',
    WeatherCondition.fog => 'Brouillard, visibilité réduite',
    WeatherCondition.drizzle => 'Bruine légère',
    WeatherCondition.rain => 'Pluie',
    WeatherCondition.showers => 'Averses passagères',
    WeatherCondition.freezingRain => 'Pluie verglaçante',
    WeatherCondition.snow => 'Chutes de neige',
    WeatherCondition.thunderstorm => 'Orages',
  };

  WeatherIconType icon({bool isDay = true}) => switch (this) {
    WeatherCondition.clear =>
      isDay ? WeatherIconType.sun : WeatherIconType.moon,
    WeatherCondition.partlyCloudy =>
      isDay ? WeatherIconType.sunCloud : WeatherIconType.moonCloud,
    WeatherCondition.cloudy => WeatherIconType.cloud,
    WeatherCondition.fog => WeatherIconType.fog,
    WeatherCondition.drizzle ||
    WeatherCondition.rain ||
    WeatherCondition.showers ||
    WeatherCondition.freezingRain => WeatherIconType.cloudRain,
    WeatherCondition.snow => WeatherIconType.cloudSnow,
    WeatherCondition.thunderstorm => WeatherIconType.cloudBolt,
  };

  PrecipitationType get precipitationType => switch (this) {
    WeatherCondition.snow => PrecipitationType.snow,
    WeatherCondition.freezingRain => PrecipitationType.ice,
    WeatherCondition.drizzle ||
    WeatherCondition.rain ||
    WeatherCondition.showers ||
    WeatherCondition.thunderstorm => PrecipitationType.rain,
    _ => PrecipitationType.none,
  };
}
