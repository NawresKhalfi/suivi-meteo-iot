import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/http_client_provider.dart';
import '../data/cities_store.dart';
import '../data/city_search_repository.dart';
import '../domain/city.dart';

final citiesStoreProvider = Provider<CitiesStore>((ref) => MemoryCitiesStore());

final citySearchRepositoryProvider = Provider<CitySearchRepository>(
  (ref) => OpenMeteoCitySearchRepository(ref.watch(httpClientProvider)),
);

final citiesControllerProvider =
    NotifierProvider<CitiesController, CitiesState>(CitiesController.new);

/// Ville actuellement affichée (accueil, prévisions, carte…).
final selectedCityProvider = Provider<City>(
  (ref) => ref.watch(citiesControllerProvider.select((s) => s.selectedCity)),
);

class CitiesState {
  const CitiesState({
    required this.cities,
    required this.defaultCityId,
    required this.selectedCityId,
  });

  final List<City> cities;
  final String defaultCityId;
  final String selectedCityId;

  City get selectedCity => cities.firstWhere(
    (city) => city.id == selectedCityId,
    orElse: () => defaultCityOrFirst,
  );

  City get defaultCityOrFirst => cities.firstWhere(
    (city) => city.id == defaultCityId,
    orElse: () => cities.first,
  );

  bool isDefault(City city) => city.id == defaultCityId;

  CitiesState copyWith({
    List<City>? cities,
    String? defaultCityId,
    String? selectedCityId,
  }) {
    return CitiesState(
      cities: cities ?? this.cities,
      defaultCityId: defaultCityId ?? this.defaultCityId,
      selectedCityId: selectedCityId ?? this.selectedCityId,
    );
  }
}

enum RemoveCityResult { removed, isDefault, lastCity }

class CitiesController extends Notifier<CitiesState> {
  CitiesStore get _store => ref.read(citiesStoreProvider);

  @override
  CitiesState build() {
    final stored = _store.read();
    final cities = stored.cities.isEmpty ? const [defaultCity] : stored.cities;
    final defaultId = cities.any((c) => c.id == stored.defaultCityId)
        ? stored.defaultCityId!
        : cities.first.id;
    // À l'ouverture, l'application affiche la ville par défaut.
    return CitiesState(
      cities: cities,
      defaultCityId: defaultId,
      selectedCityId: defaultId,
    );
  }

  /// Ajoute une ville ; renvoie `false` si elle est déjà suivie.
  Future<bool> addCity(City city) async {
    if (state.cities.contains(city)) return false;
    state = state.copyWith(cities: [...state.cities, city]);
    await _persist();
    return true;
  }

  Future<RemoveCityResult> removeCity(City city) async {
    if (state.isDefault(city)) return RemoveCityResult.isDefault;
    if (state.cities.length == 1) return RemoveCityResult.lastCity;
    final cities = state.cities.where((item) => item != city).toList();
    state = state.copyWith(
      cities: cities,
      selectedCityId: state.selectedCityId == city.id
          ? state.defaultCityId
          : state.selectedCityId,
    );
    await _persist();
    return RemoveCityResult.removed;
  }

  Future<void> setDefault(City city) async {
    state = state.copyWith(defaultCityId: city.id);
    await _persist();
  }

  void select(City city) => state = state.copyWith(selectedCityId: city.id);

  Future<void> reorder(int oldIndex, int newIndex) async {
    final cities = [...state.cities];
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    cities.insert(target, cities.removeAt(oldIndex));
    state = state.copyWith(cities: cities);
    await _persist();
  }

  Future<void> _persist() => _store.save(
    StoredCities(cities: state.cities, defaultCityId: state.defaultCityId),
  );
}
