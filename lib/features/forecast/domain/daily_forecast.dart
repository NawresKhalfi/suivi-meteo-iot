import '../../weather/domain/weather_snapshot.dart';

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.minimumTemperature,
    required this.maximumTemperature,
    required this.condition,
    required this.rainProbability,
    required this.snowProbability,
    required this.iceProbability,
    required this.lightningProbability,
    required this.sunset,
  });

  final DateTime date;
  final double minimumTemperature;
  final double maximumTemperature;
  final WeatherCondition condition;
  final int rainProbability;
  final int snowProbability;
  final int iceProbability;
  final int lightningProbability;
  final DateTime sunset;
}
