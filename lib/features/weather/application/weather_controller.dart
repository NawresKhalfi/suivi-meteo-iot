import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/weather_repository.dart';
import '../domain/weather_snapshot.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return DemoWeatherRepository();
});

final weatherLocalStoreProvider = Provider<WeatherLocalStore>((ref) {
  return MemoryWeatherLocalStore();
});

final weatherControllerProvider =
    NotifierProvider<WeatherController, AsyncValue<WeatherSnapshot>>(
      WeatherController.new,
    );

class WeatherController extends Notifier<AsyncValue<WeatherSnapshot>> {
  Timer? _refreshTimer;

  WeatherRepository get _repository => ref.read(weatherRepositoryProvider);
  WeatherLocalStore get _localStore => ref.read(weatherLocalStoreProvider);

  @override
  AsyncValue<WeatherSnapshot> build() {
    Future.microtask(_load);
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) => _load());
    ref.onDispose(() => _refreshTimer?.cancel());
    return const AsyncValue.loading();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final previous = state.valueOrNull;
    if (previous == null) state = const AsyncValue.loading();
    try {
      final snapshot = await _repository.fetchCurrentWeather();
      await _localStore.save(snapshot);
      state = AsyncValue.data(snapshot);
    } catch (error, stackTrace) {
      final cached = _localStore.read();
      state = cached == null
          ? AsyncValue.error(error, stackTrace)
          : AsyncValue.data(cached.copyWith(isOffline: true));
    }
  }
}
