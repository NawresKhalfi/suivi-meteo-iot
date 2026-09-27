import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/http_client_provider.dart';
import '../../cities/application/cities_controller.dart';
import '../data/weather_cache_store.dart';
import '../data/weather_repository.dart';
import '../domain/forecast_bundle.dart';

final weatherCacheStoreProvider = Provider<WeatherCacheStore>(
  (ref) => MemoryWeatherCacheStore(),
);

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => OpenMeteoWeatherRepository(
    ref.watch(httpClientProvider),
    ref.watch(weatherCacheStoreProvider),
  ),
);

/// Prévisions complètes de la ville sélectionnée. Se recharge
/// automatiquement au changement de ville et toutes les 15 minutes.
final weatherControllerProvider =
    AsyncNotifierProvider<WeatherController, ForecastBundle>(
      WeatherController.new,
    );

class WeatherController extends AsyncNotifier<ForecastBundle> {
  static const refreshInterval = Duration(minutes: 15);

  @override
  Future<ForecastBundle> build() {
    final city = ref.watch(selectedCityProvider);
    final timer = Timer.periodic(refreshInterval, (_) => refresh());
    ref.onDispose(timer.cancel);
    return ref.read(weatherRepositoryProvider).fetchForecast(city);
  }

  /// Actualisation manuelle (E01 – US04). Garde l'affichage courant pendant
  /// le chargement et en cas d'erreur.
  Future<void> refresh() async {
    final city = ref.read(selectedCityProvider);
    final result = await AsyncValue.guard(
      () => ref.read(weatherRepositoryProvider).fetchForecast(city),
    );
    if (result.hasError && state.hasValue) return;
    state = result;
  }
}

/// Météo actuelle de toutes les villes suivies (écran « Mes villes »).
final citiesWeatherProvider = FutureProvider<Map<String, CityCurrentWeather>>((
  ref,
) {
  final cities = ref.watch(citiesControllerProvider.select((s) => s.cities));
  return ref.read(weatherRepositoryProvider).fetchCurrentForCities(cities);
});
