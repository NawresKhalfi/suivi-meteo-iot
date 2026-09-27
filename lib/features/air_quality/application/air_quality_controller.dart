import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/http_client_provider.dart';
import '../../cities/application/cities_controller.dart';
import '../data/air_quality_repository.dart';
import '../domain/air_quality_snapshot.dart';

final airQualityRepositoryProvider = Provider<AirQualityRepository>(
  (ref) => OpenMeteoAirQualityRepository(ref.watch(httpClientProvider)),
);

/// Qualité de l'air de la ville sélectionnée (E07 – US19, US20).
final airQualityProvider = FutureProvider<AirQualitySnapshot>((ref) {
  final city = ref.watch(selectedCityProvider);
  return ref.read(airQualityRepositoryProvider).fetchCurrent(city);
});
