import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/weather/application/weather_controller.dart';
import 'package:meteo/features/weather/data/weather_repository.dart';
import 'package:meteo/features/weather/domain/weather_snapshot.dart';

class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherSnapshot> fetchCurrentWeather() async => WeatherSnapshot(
    city: 'Lyon',
    temperature: 18,
    condition: WeatherCondition.cloudy,
    windSpeed: 8,
    windDirection: 'N',
    humidity: 60,
    pressure: 1008,
    uvIndex: 2,
    visibility: 9,
    dewPoint: 10,
    elevation: 170,
    updatedAt: DateTime(2026, 9, 11),
  );
}

class _FailingWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherSnapshot> fetchCurrentWeather() {
    return Future<WeatherSnapshot>.error(Exception('offline'));
  }
}

void main() {
  test('charge la météo depuis le repository injecté', () async {
    final container = ProviderContainer(
      overrides: [
        weatherRepositoryProvider.overrideWithValue(_FakeWeatherRepository()),
        weatherLocalStoreProvider.overrideWithValue(MemoryWeatherLocalStore()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(weatherControllerProvider.notifier).refresh();

    expect(container.read(weatherControllerProvider).value?.city, 'Lyon');
  });

  test('utilise la dernière météo connue si le réseau échoue', () async {
    final localStore = MemoryWeatherLocalStore();
    await localStore.save(await _FakeWeatherRepository().fetchCurrentWeather());
    final container = ProviderContainer(
      overrides: [
        weatherRepositoryProvider.overrideWithValue(
          _FailingWeatherRepository(),
        ),
        weatherLocalStoreProvider.overrideWithValue(localStore),
      ],
    );
    addTearDown(container.dispose);

    await container.read(weatherControllerProvider.notifier).refresh();

    final state = container.read(weatherControllerProvider);
    expect(state.value?.city, 'Lyon');
    expect(state.value?.isOffline, isTrue);
  });
}
