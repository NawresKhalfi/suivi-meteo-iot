import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cities_store.dart';
import '../domain/city.dart';

final citiesStoreProvider = Provider<CitiesStore>((ref) => MemoryCitiesStore());

final citiesControllerProvider =
    NotifierProvider<CitiesController, CitiesState>(CitiesController.new);

class CitiesState {
  const CitiesState({this.cities = const [], this.selectedCityId});

  final List<City> cities;
  final String? selectedCityId;

  CitiesState copyWith({List<City>? cities, String? selectedCityId}) {
    return CitiesState(
      cities: cities ?? this.cities,
      selectedCityId: selectedCityId ?? this.selectedCityId,
    );
  }
}

class CitiesController extends Notifier<CitiesState> {
  CitiesStore get _store => ref.read(citiesStoreProvider);

  @override
  CitiesState build() {
    final saved = _store.read();
    final cities = saved.isEmpty
        ? const [City(name: 'Paris', country: 'France', isFavorite: true)]
        : saved;
    return CitiesState(
      cities: cities,
      selectedCityId: _store.readSelected() ?? cities.first.id,
    );
  }

  List<City> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return state.cities;
    return state.cities
        .where(
          (city) =>
              city.name.toLowerCase().contains(normalized) ||
              city.country.toLowerCase().contains(normalized),
        )
        .toList();
  }

  Future<void> addCity(String name, String country) async {
    final city = City(name: name.trim(), country: country.trim());
    if (city.name.isEmpty ||
        city.country.isEmpty ||
        state.cities.any(
          (item) => item.id.toLowerCase() == city.id.toLowerCase(),
        )) {
      return;
    }
    final cities = [...state.cities, city];
    state = state.copyWith(cities: cities);
    await _store.save(cities);
  }

  Future<void> removeCity(City city) async {
    if (state.cities.length == 1) return;
    final cities = state.cities.where((item) => item.id != city.id).toList();
    final selected = state.selectedCityId == city.id
        ? cities.first.id
        : state.selectedCityId;
    state = CitiesState(cities: cities, selectedCityId: selected);
    await _store.save(cities);
    if (selected != null) await _store.saveSelected(selected);
  }

  Future<void> toggleFavorite(City city) async {
    final cities = state.cities
        .map(
          (item) => item.id == city.id
              ? item.copyWith(isFavorite: !item.isFavorite)
              : item,
        )
        .toList();
    state = state.copyWith(cities: cities);
    await _store.save(cities);
  }

  Future<void> select(City city) async {
    state = state.copyWith(selectedCityId: city.id);
    await _store.saveSelected(city.id);
  }
}
