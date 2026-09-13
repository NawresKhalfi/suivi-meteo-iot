import '../../weather/domain/weather_snapshot.dart';

enum PrecipitationType { none, rain, snow, ice }

class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.condition,
    required this.precipitationType,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.windGust,
    required this.windDirection,
  });

  final DateTime time;
  final double temperature;
  final WeatherCondition condition;
  final PrecipitationType precipitationType;
  final int precipitationProbability;
  final double windSpeed;
  final double windGust;
  final String windDirection;
}
