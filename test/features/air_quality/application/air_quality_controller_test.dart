import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/air_quality/application/air_quality_controller.dart';
import 'package:meteo/features/air_quality/domain/air_quality_snapshot.dart';

void main() {
  test('calcule les niveaux AQI normalisés', () {
    expect(airQualityLevelForAqi(40), AirQualityLevel.good);
    expect(airQualityLevelForAqi(120), AirQualityLevel.unhealthy);
    expect(airQualityLevelForAqi(240), AirQualityLevel.hazardous);
  });

  test('charge les six polluants', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final snapshot = await container.read(airQualityControllerProvider.future);

    expect(snapshot.pollutants, hasLength(6));
    expect(snapshot.level, AirQualityLevel.good);
  });
}
