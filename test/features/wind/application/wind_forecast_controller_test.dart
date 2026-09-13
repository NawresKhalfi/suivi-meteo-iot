import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/wind/application/wind_forecast_controller.dart';
import 'package:meteo/features/wind/data/wind_forecast_repository.dart';
import 'package:meteo/features/wind/domain/wind_forecast.dart';

class _FakeWindForecastRepository implements WindForecastRepository {
  @override
  Future<List<WindForecast>> fetchNext10Days() async {
    final date = DateTime(2026, 9, 12);
    return List.generate(
      10,
      (index) => WindForecast(
        date: date.add(Duration(days: index)),
        speed: 10,
        gust: 16,
        direction: 'O',
        directionDegrees: 270,
      ),
    );
  }
}

void main() {
  test('charge dix points de vent', () async {
    final container = ProviderContainer(
      overrides: [
        windForecastRepositoryProvider.overrideWithValue(
          _FakeWindForecastRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final forecast = await container.read(
      windForecastControllerProvider.future,
    );

    expect(forecast, hasLength(10));
    expect(forecast.first.directionDegrees, 270);
  });
}
