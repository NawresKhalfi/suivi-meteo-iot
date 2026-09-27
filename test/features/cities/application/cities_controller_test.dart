import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/cities/application/cities_controller.dart';
import 'package:meteo/features/cities/data/cities_store.dart';
import 'package:meteo/features/cities/domain/city.dart';

const paris = City(
  name: 'Paris',
  country: 'France',
  latitude: 48.8534,
  longitude: 2.3488,
);
const tunis = City(
  name: 'Tunis',
  country: 'Tunisie',
  latitude: 36.819,
  longitude: 10.1658,
);

void main() {
  late MemoryCitiesStore store;
  late ProviderContainer container;
  CitiesController controller() =>
      container.read(citiesControllerProvider.notifier);
  CitiesState state() => container.read(citiesControllerProvider);

  setUp(() {
    store = MemoryCitiesStore();
    container = ProviderContainer(
      overrides: [citiesStoreProvider.overrideWithValue(store)],
    );
  });
  tearDown(() => container.dispose());

  test('premier lancement : Nabeul par défaut et sélectionnée', () {
    expect(state().cities, [defaultCity]);
    expect(state().selectedCity, defaultCity);
    expect(state().isDefault(defaultCity), isTrue);
  });

  test('ajoute une ville sans doublon et persiste', () async {
    expect(await controller().addCity(paris), isTrue);
    expect(await controller().addCity(paris), isFalse);
    expect(state().cities, [defaultCity, paris]);
    expect(store.value.cities, [defaultCity, paris]);
  });

  test(
    'la ville localisée devient la ville par défaut et sélectionnée',
    () async {
      await controller().addLocatedCity(paris);
      expect(state().cities, [defaultCity, paris]);
      expect(state().isDefault(paris), isTrue);
      expect(state().selectedCity, paris);
      expect(store.value.defaultCityId, paris.id);

      await controller().addLocatedCity(paris);
      expect(state().cities, [defaultCity, paris]);
    },
  );

  test('la ville par défaut ne peut pas être supprimée', () async {
    await controller().addCity(paris);
    expect(
      await controller().removeCity(defaultCity),
      RemoveCityResult.isDefault,
    );
    expect(await controller().removeCity(paris), RemoveCityResult.removed);
    expect(state().cities, [defaultCity]);
  });

  test(
    'supprimer la ville sélectionnée revient à la ville par défaut',
    () async {
      await controller().addCity(paris);
      controller().select(paris);
      expect(container.read(selectedCityProvider), paris);
      await controller().removeCity(paris);
      expect(container.read(selectedCityProvider), defaultCity);
    },
  );

  test('définit la ville par défaut, utilisée au prochain lancement', () async {
    await controller().addCity(paris);
    await controller().setDefault(paris);
    expect(store.value.defaultCityId, paris.id);

    final next = ProviderContainer(
      overrides: [citiesStoreProvider.overrideWithValue(store)],
    );
    addTearDown(next.dispose);
    expect(next.read(selectedCityProvider), paris);
  });

  test('réordonne les villes', () async {
    await controller().addCity(paris);
    await controller().addCity(tunis);
    await controller().reorder(2, 0);
    expect(state().cities, [tunis, defaultCity, paris]);
    await controller().reorder(0, 3);
    expect(state().cities, [defaultCity, paris, tunis]);
  });
}
