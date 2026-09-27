import '../../../core/format/french_calendar.dart';
import '../../weather/domain/weather_condition.dart';

/// Prévision journalière (E04 – US13 à US15, E05, E06).
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.minimumTemperature,
    required this.maximumTemperature,
    required this.weatherCode,
    required this.rainProbability,
    required this.precipitationSum,
    required this.snowProbability,
    required this.iceProbability,
    required this.lightningProbability,
    required this.windSpeed,
    required this.windGust,
    required this.windDirectionDegrees,
    required this.uvIndex,
    required this.humidity,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date;
  final double minimumTemperature;
  final double maximumTemperature;
  final int weatherCode;
  final int rainProbability;
  final double precipitationSum;
  final int snowProbability;
  final int iceProbability;
  final int lightningProbability;
  final double windSpeed;
  final double windGust;
  final int windDirectionDegrees;
  final double uvIndex;
  final int humidity;
  final DateTime sunrise;
  final DateTime sunset;

  WeatherCondition get condition => conditionFromWmo(weatherCode);
  String get windDirection => compassLabel(windDirectionDegrees);
}
