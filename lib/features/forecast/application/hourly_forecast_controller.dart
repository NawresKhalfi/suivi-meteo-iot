import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hourly_forecast_repository.dart';
import '../domain/hourly_forecast.dart';

final hourlyForecastRepositoryProvider = Provider<HourlyForecastRepository>(
  (ref) => DemoHourlyForecastRepository(),
);

final hourlyForecastControllerProvider =
    AsyncNotifierProvider<HourlyForecastController, List<HourlyForecast>>(
      HourlyForecastController.new,
    );

class HourlyForecastController extends AsyncNotifier<List<HourlyForecast>> {
  HourlyForecastRepository get _repository =>
      ref.read(hourlyForecastRepositoryProvider);

  @override
  Future<List<HourlyForecast>> build() => _repository.fetchNext24Hours();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchNext24Hours);
  }
}
