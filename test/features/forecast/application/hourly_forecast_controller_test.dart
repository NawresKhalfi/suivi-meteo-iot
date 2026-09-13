import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/forecast/application/hourly_forecast_controller.dart';
import 'package:meteo/features/forecast/data/hourly_forecast_repository.dart';
import 'package:meteo/features/forecast/domain/hourly_forecast.dart';
import 'package:meteo/features/weather/domain/weather_snapshot.dart';

class _FakeHourlyForecastRepository implements HourlyForecastRepository {
  @override
  Future<List<HourlyForecast>> fetchNext24Hours() async {
    final now = DateTime(2026, 9, 12, 8);
    return List.generate(
      24,
      (index) => HourlyForecast(
        time: now.add(Duration(hours: index)),
        temperature: 20,
        condition: WeatherCondition.cloudy,
        precipitationType: PrecipitationType.rain,
        precipitationProbability: 10,
        windSpeed: 8,
        windGust: 12,
        windDirection: 'N',
      ),
    );
  }
}

void main() {
  test('charge 24 créneaux horaires', () async {
    final container = ProviderContainer(
      overrides: [
        hourlyForecastRepositoryProvider.overrideWithValue(
          _FakeHourlyForecastRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final forecast = await container.read(
      hourlyForecastControllerProvider.future,
    );

    expect(forecast, hasLength(24));
    expect(forecast.first.windDirection, 'N');
  });
}
