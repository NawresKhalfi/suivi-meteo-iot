import '../../../core/format/french_calendar.dart';
import 'weather_condition.dart';

/// Conditions actuelles (E01 – US01 à US03).
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.temperature,
    required this.apparentTemperature,
    required this.condition,
    required this.isDay,
    required this.windSpeed,
    required this.windGust,
    required this.windDirectionDegrees,
    required this.humidity,
    required this.pressure,
    required this.uvIndex,
    required this.visibility,
    required this.dewPoint,
    required this.elevation,
    required this.observedAt,
    required this.updatedAt,
    this.isOffline = false,
  });

  final String city;
  final double temperature;
  final double apparentTemperature;
  final WeatherCondition condition;
  final bool isDay;

  /// km/h
  final double windSpeed;
  final double windGust;
  final int windDirectionDegrees;

  /// %
  final double humidity;

  /// hPa (niveau de la mer)
  final double pressure;
  final double uvIndex;

  /// mètres
  final double visibility;
  final double dewPoint;

  /// mètres
  final double elevation;

  /// Heure locale de la ville au moment de l'observation.
  final DateTime observedAt;

  /// Heure (appareil) à laquelle la donnée a été téléchargée.
  final DateTime updatedAt;
  final bool isOffline;

  String get windDirection => compassLabel(windDirectionDegrees);
}

String uvLevelLabel(double uv) {
  if (uv < 3) return 'Faible';
  if (uv < 6) return 'Modéré';
  if (uv < 8) return 'Élevé';
  if (uv < 11) return 'Très élevé';
  return 'Extrême';
}

String uvAdvice(double uv) {
  if (uv < 3) return 'Aucune protection nécessaire';
  if (uv < 6) return 'Protection conseillée';
  if (uv < 8) return 'Chapeau et crème solaire';
  return 'Évitez le soleil entre 12h et 16h';
}
