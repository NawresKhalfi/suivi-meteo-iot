import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/air_quality/application/air_quality_controller.dart';
import 'package:meteo/features/air_quality/data/air_quality_repository.dart';
import 'package:meteo/features/air_quality/domain/air_quality_snapshot.dart';
import 'package:meteo/features/cities/domain/city.dart';

import '../../../helpers/pump_app.dart';

class _FailingAirQualityRepository implements AirQualityRepository {
  @override
  Future<AirQualitySnapshot> fetchCurrent(City city) =>
      Future.error(Exception('offline'));
}

/// E07 — Qualité de l'air.
void main() {
  testWidgets("US19 : l'accueil résume l'indice et le niveau", (tester) async {
    await pumpApp(tester);
    expect(find.text("Qualité de l'air"), findsOneWidget);
    expect(find.text('42 · Bon'), findsOneWidget);
    expect(find.text('PM2.5 9 µg/m³'), findsOneWidget);
  });

  testWidgets('US19/US20 : la feuille détaille indice, conseil et polluants', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('42 · Bon'));

    expect(find.text("Qualité de l'air — Nabeul"), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Bon'), findsOneWidget);
    expect(find.text(AirQualityLevel.good.advice), findsOneWidget);
    expect(find.text('PM2.5'), findsOneWidget);
    expect(find.text('9,0 µg/m³'), findsOneWidget);
    expect(find.text('O3'), findsOneWidget);
    expect(find.text('103 µg/m³'), findsOneWidget);
    expect(find.textContaining('Source : Open-Meteo / CAMS'), findsOneWidget);
  });

  testWidgets('données indisponibles : message explicite', (tester) async {
    await pumpApp(
      tester,
      overrides: [
        airQualityRepositoryProvider.overrideWithValue(
          _FailingAirQualityRepository(),
        ),
      ],
    );
    expect(find.text('Indisponible'), findsOneWidget);

    await tapVisible(tester, find.text('Indisponible'));
    expect(
      find.text("Données de qualité de l'air indisponibles pour le moment."),
      findsOneWidget,
    );
  });
}
