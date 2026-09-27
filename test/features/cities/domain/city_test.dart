import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/core/storage/local_preferences.dart';
import 'package:meteo/features/cities/data/cities_store.dart';
import 'package:meteo/features/cities/domain/city.dart';
import 'package:shared_preferences/shared_preferences.dart';

const paris = City(
  name: 'Paris',
  country: 'France',
  region: 'Île-de-France',
  latitude: 48.8534,
  longitude: 2.3488,
);

void main() {
  group('City', () {
    test('identifiant stable basé sur les coordonnées (≈ 100 m)', () {
      expect(paris.id, '48.853,2.349');
      const nearby = City(
        name: 'Paris 1er',
        country: 'France',
        latitude: 48.85341,
        longitude: 2.34879,
      );
      expect(nearby, paris);
      expect(nearby.hashCode, paris.hashCode);
    });

    test('sous-titre : région et pays, sans répéter le nom', () {
      expect(paris.subtitle, 'Île-de-France, France');
      expect(defaultCity.subtitle, 'Tunisie');
      const sousse = City(
        name: 'Sousse',
        country: 'Tunisie',
        region: 'Sousse',
        latitude: 35.8254,
        longitude: 10.637,
      );
      expect(sousse.subtitle, 'Tunisie');
    });

    test('sérialisation JSON aller-retour', () {
      final copy = City.fromJson(paris.toJson());
      expect(copy.name, 'Paris');
      expect(copy.region, 'Île-de-France');
      expect(copy.latitude, paris.latitude);
      expect(copy, paris);
    });

    test('suggestions populaires sans doublon', () {
      expect(popularCities.map((c) => c.id).toSet(), hasLength(10));
      expect(popularCities.map((c) => c.name), contains('Tunis'));
    });
  });

  group('SharedPreferencesCitiesStore', () {
    Future<SharedPreferencesCitiesStore> store([
      Map<String, Object> values = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferencesCitiesStore(
        LocalPreferences(await SharedPreferences.getInstance()),
      );
    }

    test('vide au premier lancement', () async {
      final stored = (await store()).read();
      expect(stored.cities, isEmpty);
      expect(stored.defaultCityId, isNull);
    });

    test('persiste villes et ville par défaut', () async {
      final s = await store();
      await s.save(
        StoredCities(cities: [defaultCity, paris], defaultCityId: paris.id),
      );
      final stored = s.read();
      expect(stored.cities, [defaultCity, paris]);
      expect(stored.defaultCityId, paris.id);
    });

    test('des données corrompues sont ignorées', () async {
      final stored = (await store({'cities.v2': '{oops'})).read();
      expect(stored.cities, isEmpty);
    });
  });
}
