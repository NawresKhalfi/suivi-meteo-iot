import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/astronomy/domain/astronomy_snapshot.dart';
import 'package:meteo/features/astronomy/presentation/widgets/astronomy_sheet.dart';
import 'package:meteo/features/settings/application/settings_controller.dart';
import 'package:meteo/features/settings/data/settings_store.dart';
import 'package:meteo/features/settings/domain/unit_settings.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

/// E09 — Lever / coucher du soleil et phases lunaires.
void main() {
  testWidgets("US24 : l'accueil affiche le coucher et le lever du soleil", (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Coucher du soleil'), findsOneWidget);
    expect(find.text('18:06'), findsOneWidget);
    expect(find.text('Lever à 06:08'), findsOneWidget);
  });

  testWidgets('US24/US25 : la carte ouvre « Soleil & Lune »', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.text('Coucher du soleil'));

    final astronomy = loadBundle().astronomy;
    expect(find.text('Soleil & Lune'), findsOneWidget);
    expect(find.text('Lever'), findsOneWidget);
    expect(find.text('06:08'), findsOneWidget);
    expect(find.text('Durée du jour'), findsOneWidget);
    expect(find.text('11 h 58'), findsOneWidget);
    expect(find.text('Coucher'), findsOneWidget);
    expect(find.text('Phase lunaire'), findsOneWidget);
    expect(find.text(astronomy.moonPhase.label), findsOneWidget);
    expect(find.text(astronomy.moonPhase.icon), findsOneWidget);
  });

  testWidgets('US25 : phase lunaire et horaires au format 12 h', (
    tester,
  ) async {
    final settings = MemorySettingsStore()
      ..value = const UnitSettings(timeFormat: TimeFormat.h12);
    await pumpWidgetInApp(
      tester,
      AstronomySheet(
        astronomy: AstronomySnapshot(
          sunrise: DateTime(2026, 9, 27, 6, 30),
          sunset: DateTime(2026, 9, 27, 19, 15),
          moonPhase: MoonPhase.waningGibbous,
          observedAt: DateTime(2026, 9, 27, 22),
        ),
      ),
      overrides: [settingsStoreProvider.overrideWithValue(settings)],
    );
    expect(find.text('6:30 AM'), findsOneWidget);
    expect(find.text('7:15 PM'), findsOneWidget);
    expect(find.text('12 h 45'), findsOneWidget);
    expect(find.text('Gibbeuse décroissante'), findsOneWidget);
    expect(find.text('🌖'), findsOneWidget);
  });
}
