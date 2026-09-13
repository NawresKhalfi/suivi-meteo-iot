import 'dart:convert';

import '../../../core/storage/local_preferences.dart';
import '../domain/city.dart';

abstract interface class CitiesStore {
  List<City> read();
  String? readSelected();
  Future<void> save(List<City> cities);
  Future<void> saveSelected(String cityId);
}

class SharedPreferencesCitiesStore implements CitiesStore {
  SharedPreferencesCitiesStore(this._preferences);

  final LocalPreferences _preferences;

  @override
  List<City> read() {
    final value = _preferences.savedCities;
    if (value == null) return const [];
    try {
      return (jsonDecode(value) as List<dynamic>).map((item) {
        final json = item as Map<String, dynamic>;
        return City(
          name: json['name'] as String,
          country: json['country'] as String,
          isFavorite: json['isFavorite'] as bool? ?? false,
        );
      }).toList();
    } on Object {
      return const [];
    }
  }

  @override
  String? readSelected() => _preferences.selectedCity;

  @override
  Future<void> save(List<City> cities) {
    return _preferences.saveCities(
      jsonEncode(
        cities
            .map(
              (city) => {
                'name': city.name,
                'country': city.country,
                'isFavorite': city.isFavorite,
              },
            )
            .toList(),
      ),
    );
  }

  @override
  Future<void> saveSelected(String cityId) =>
      _preferences.saveSelectedCity(cityId);
}

class MemoryCitiesStore implements CitiesStore {
  List<City> cities = const [];
  String? selected;

  @override
  List<City> read() => cities;

  @override
  String? readSelected() => selected;

  @override
  Future<void> save(List<City> value) async => cities = List.of(value);

  @override
  Future<void> saveSelected(String cityId) async => selected = cityId;
}
