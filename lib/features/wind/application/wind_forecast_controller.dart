import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wind_forecast_repository.dart';
import '../domain/wind_forecast.dart';

final windForecastRepositoryProvider = Provider<WindForecastRepository>(
  (ref) => DemoWindForecastRepository(),
);

final windForecastControllerProvider =
    AsyncNotifierProvider<WindForecastController, List<WindForecast>>(
      WindForecastController.new,
    );

class WindForecastController extends AsyncNotifier<List<WindForecast>> {
  WindForecastRepository get _repository =>
      ref.read(windForecastRepositoryProvider);

  @override
  Future<List<WindForecast>> build() => _repository.fetchNext10Days();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchNext10Days);
  }
}
