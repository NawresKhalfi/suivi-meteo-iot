import 'dart:convert';

import '../../../core/storage/local_preferences.dart';
import '../domain/city.dart';

class StoredCities {
  const StoredCities({required this.cities, this.defaultCityId});

  final List<City> cities;
  final String? defaultCityId;
}

abstract interface class CitiesStore {
  StoredCities read();
  Future<void> save(StoredCities value);
}

class SharedPreferencesCitiesStore implements CitiesStore {
  SharedPreferencesCitiesStore(this._preferences);

  final LocalPreferences _preferences;

  @override
  StoredCities read() {
    final value = _preferences.savedCities;
    if (value == null) return const StoredCities(cities: []);
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return StoredCities(
        cities: (json['cities'] as List<dynamic>)
            .map((item) => City.fromJson(item as Map<String, dynamic>))
            .toList(),
        defaultCityId: json['default'] as String?,
      );
    } on Object {
      return const StoredCities(cities: []);
    }
  }

  @override
  Future<void> save(StoredCities value) => _preferences.saveCities(
    jsonEncode({
      'cities': value.cities.map((city) => city.toJson()).toList(),
      'default': value.defaultCityId,
    }),
  );
}

class MemoryCitiesStore implements CitiesStore {
  MemoryCitiesStore([this.value = const StoredCities(cities: [])]);

  StoredCities value;

  @override
  StoredCities read() => value;

  @override
  Future<void> save(StoredCities value) async => this.value = value;
}
