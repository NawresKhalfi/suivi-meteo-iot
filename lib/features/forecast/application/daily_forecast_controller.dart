import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daily_forecast_repository.dart';
import '../domain/daily_forecast.dart';

final dailyForecastRepositoryProvider = Provider<DailyForecastRepository>(
  (ref) => DemoDailyForecastRepository(),
);

final dailyForecastControllerProvider =
    AsyncNotifierProvider<DailyForecastController, List<DailyForecast>>(
      DailyForecastController.new,
    );

class DailyForecastController extends AsyncNotifier<List<DailyForecast>> {
  DailyForecastRepository get _repository =>
      ref.read(dailyForecastRepositoryProvider);

  @override
  Future<List<DailyForecast>> build() => _repository.fetchNext10Days();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchNext10Days);
  }
}
