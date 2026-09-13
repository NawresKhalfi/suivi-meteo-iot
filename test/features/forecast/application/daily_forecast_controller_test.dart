import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/forecast/application/daily_forecast_controller.dart';
import 'package:meteo/features/forecast/data/daily_forecast_repository.dart';
import 'package:meteo/features/forecast/domain/daily_forecast.dart';
import 'package:meteo/features/weather/domain/weather_snapshot.dart';

class _FakeDailyForecastRepository implements DailyForecastRepository {
  @override
  Future<List<DailyForecast>> fetchNext10Days() async {
    final date = DateTime(2026, 9, 12);
    return List.generate(
      10,
      (index) => DailyForecast(
        date: date.add(Duration(days: index)),
        minimumTemperature: 12,
        maximumTemperature: 22,
        condition: WeatherCondition.sunny,
        rainProbability: 10,
        snowProbability: 1,
        iceProbability: 1,
        lightningProbability: 2,
        sunset: date.add(const Duration(hours: 19)),
      ),
    );
  }
}

void main() {
  test('charge dix journées de prévisions', () async {
    final container = ProviderContainer(
      overrides: [
        dailyForecastRepositoryProvider.overrideWithValue(
          _FakeDailyForecastRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final forecast = await container.read(
      dailyForecastControllerProvider.future,
    );

    expect(forecast, hasLength(10));
    expect(forecast.first.maximumTemperature, 22);
  });
}
