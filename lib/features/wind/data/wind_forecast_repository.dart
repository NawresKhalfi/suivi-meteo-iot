import '../domain/wind_forecast.dart';

abstract interface class WindForecastRepository {
  Future<List<WindForecast>> fetchNext10Days();
}

class DemoWindForecastRepository implements WindForecastRepository {
  @override
  Future<List<WindForecast>> fetchNext10Days() async {
    final now = DateTime.now();
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    return List.generate(10, (index) {
      return WindForecast(
        date: DateTime(now.year, now.month, now.day + index),
        speed: 8 + index * 0.8,
        gust: 14.0 + index,
        direction: directions[index % directions.length],
        directionDegrees: (index * 45) % 360,
      );
    });
  }
}
