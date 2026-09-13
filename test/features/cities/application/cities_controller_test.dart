import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meteo/features/cities/application/cities_controller.dart';
import 'package:meteo/features/cities/data/cities_store.dart';

void main() {
  test('ajoute, recherche, sélectionne et marque une ville', () async {
    final store = MemoryCitiesStore();
    final container = ProviderContainer(
      overrides: [citiesStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(citiesControllerProvider.notifier);
    await controller.addCity('Lyon', 'France');
    expect(controller.search('lyon').single.name, 'Lyon');
    await controller.toggleFavorite(controller.search('Lyon').single);
    await controller.select(controller.search('Lyon').single);
    expect(
      container.read(citiesControllerProvider).selectedCityId,
      'Lyon|France',
    );
    expect(
      store.cities.singleWhere((city) => city.name == 'Lyon').isFavorite,
      isTrue,
    );
  });
}
