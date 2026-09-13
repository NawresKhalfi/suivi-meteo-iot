import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/air_quality_repository.dart';
import '../domain/air_quality_snapshot.dart';

final airQualityRepositoryProvider = Provider<AirQualityRepository>(
  (ref) => DemoAirQualityRepository(),
);

final airQualityControllerProvider =
    AsyncNotifierProvider<AirQualityController, AirQualitySnapshot>(
      AirQualityController.new,
    );

class AirQualityController extends AsyncNotifier<AirQualitySnapshot> {
  AirQualityRepository get _repository =>
      ref.read(airQualityRepositoryProvider);

  @override
  Future<AirQualitySnapshot> build() => _repository.fetchCurrentAirQuality();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchCurrentAirQuality);
  }
}
