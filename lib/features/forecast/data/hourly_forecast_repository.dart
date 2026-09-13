import '../../weather/domain/weather_snapshot.dart';
import '../domain/hourly_forecast.dart';

abstract interface class HourlyForecastRepository {
  Future<List<HourlyForecast>> fetchNext24Hours();
}

class DemoHourlyForecastRepository implements HourlyForecastRepository {
  @override
  Future<List<HourlyForecast>> fetchNext24Hours() async {
    final now = DateTime.now();
    return List.generate(24, (index) {
      final hour = now.add(Duration(hours: index));
      final isRainy = index % 7 == 3 || index % 7 == 4;
      final precipitationType = index % 11 == 5
          ? PrecipitationType.snow
          : index % 13 == 6
          ? PrecipitationType.ice
          : isRainy
          ? PrecipitationType.rain
          : PrecipitationType.none;
      return HourlyForecast(
        time: hour,
        temperature: 18 + (index % 8) * 0.8,
        condition: isRainy ? WeatherCondition.rainy : WeatherCondition.cloudy,
        precipitationType: precipitationType,
        precipitationProbability: isRainy ? 65 : 15 + index % 4 * 5,
        windSpeed: 8 + index % 5,
        windGust: 15 + index % 6,
        windDirection: const [
          'N',
          'NE',
          'E',
          'SE',
          'S',
          'SO',
          'O',
          'NO',
        ][index % 8],
      );
    });
  }
}
