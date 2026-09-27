import '../../../core/format/french_calendar.dart';
import '../../weather/domain/weather_condition.dart';

/// Prévision horaire (E03 – US10 à US12).
class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.isDay,
    required this.precipitationProbability,
    required this.precipitation,
    required this.windSpeed,
    required this.windGust,
    required this.windDirectionDegrees,
    required this.humidity,
  });

  final DateTime time;
  final double temperature;
  final int weatherCode;
  final bool isDay;
  final int precipitationProbability;

  /// mm
  final double precipitation;
  final double windSpeed;
  final double windGust;
  final int windDirectionDegrees;
  final int humidity;

  WeatherCondition get condition => conditionFromWmo(weatherCode);
  PrecipitationType get precipitationType => condition.precipitationType;
  String get windDirection => compassLabel(windDirectionDegrees);
}
