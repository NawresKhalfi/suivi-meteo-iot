import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/cities/application/cities_controller.dart';
import 'package:meteo/features/cities/domain/city.dart';
import 'package:meteo/features/weather/application/weather_controller.dart';

import '../../../helpers/fakes.dart';

void main() {
  test('charge la météo de la ville sélectionnée', () async {
    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    final bundle = await container.read(weatherControllerProvider.future);
    expect(bundle.current.city, 'Nabeul');
  });

  test('recharge au changement de ville', () async {
    final weather = FakeWeatherRepository();
    final container = ProviderContainer(
      overrides: testOverrides(weather: weather),
    );
    addTearDown(container.dispose);
    await container.read(weatherControllerProvider.future);

    const paris = City(
      name: 'Paris',
      country: 'France',
      latitude: 48.85,
      longitude: 2.35,
    );
    final cities = container.read(citiesControllerProvider.notifier);
    await cities.addCity(paris);
    cities.select(paris);
    final bundle = await container.read(weatherControllerProvider.future);
    expect(bundle.current.city, 'Paris');
    expect(weather.forecastCalls, 2);
  });

  test(
    "l'actualisation manuelle conserve l'affichage en cas d'échec",
    () async {
      final weather = FakeWeatherRepository();
      final container = ProviderContainer(
        overrides: testOverrides(weather: weather),
      );
      addTearDown(container.dispose);
      await container.read(weatherControllerProvider.future);

      weather.fail = true;
      await container.read(weatherControllerProvider.notifier).refresh();
      final state = container.read(weatherControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.value!.current.city, 'Nabeul');
    },
  );

  test('météo de toutes les villes suivies', () async {
    final container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    final result = await container.read(citiesWeatherProvider.future);
    expect(result[defaultCity.id]!.temperature, 20);
  });
}
