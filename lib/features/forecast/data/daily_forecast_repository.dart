import '../../weather/domain/weather_snapshot.dart';
import '../domain/daily_forecast.dart';

abstract interface class DailyForecastRepository {
  Future<List<DailyForecast>> fetchNext10Days();
}

class DemoDailyForecastRepository implements DailyForecastRepository {
  @override
  Future<List<DailyForecast>> fetchNext10Days() async {
    final now = DateTime.now();
    return List.generate(10, (index) {
      final date = DateTime(now.year, now.month, now.day + index);
      return DailyForecast(
        date: date,
        minimumTemperature: 12 + index % 4,
        maximumTemperature: 20 + index % 6,
        condition: index % 4 == 2
            ? WeatherCondition.rainy
            : index % 3 == 0
            ? WeatherCondition.sunny
            : WeatherCondition.cloudy,
        rainProbability: 10 + (index * 13) % 70,
        snowProbability: index == 6 ? 22 : 2,
        iceProbability: index == 7 ? 15 : 1,
        lightningProbability: index % 5 == 2 ? 25 : 3,
        sunset: date.add(const Duration(hours: 19, minutes: 30)),
      );
    });
  }
}
