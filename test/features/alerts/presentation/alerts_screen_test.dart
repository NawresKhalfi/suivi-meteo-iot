import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/alerts/application/alerts_controller.dart';
import 'package:meteo/features/alerts/data/alerts_repository.dart';
import 'package:meteo/features/alerts/domain/alert_rules.dart';
import 'package:meteo/features/alerts/domain/weather_alert.dart';
import 'package:meteo/features/cities/domain/city.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

const _storm = {
  'weather_code': 95,
  'wind_gusts_10m': 75.0,
  'precipitation': 9.0,
};

/// Orage en cours : l'observation est à 16h15.
FakeWeatherRepository activeStorm() => FakeWeatherRepository(
  json: patchedForecastJson(_storm, from: '2026-09-27T16:00'),
);

/// Orage prévu de 18h à 21h.
FakeWeatherRepository upcomingStorm() =>
    FakeWeatherRepository(json: patchedForecastJson(_storm));

/// E02 — Alertes météo et catastrophes naturelles.
void main() {
  testWidgets("une alerte en cours s'affiche en bandeau sur l'accueil", (
    tester,
  ) async {
    await pumpApp(tester, weather: activeStorm());
    expect(find.text('Alerte orages violents'), findsOneWidget);
    expect(find.textContaining('Toucher pour le détail'), findsWidgets);
  });

  testWidgets('US07 : le bandeau ouvre le détail complet de l’alerte', (
    tester,
  ) async {
    await pumpApp(tester, weather: activeStorm());
    await tester.tap(find.text('Alerte orages violents'));
    await settle(tester);

    expect(find.text('Danger — Vigilance orange'), findsWidgets);
    expect(find.text('Zone affectée'), findsOneWidget);
    expect(find.text('Nabeul et environs'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    expect(find.text('Open-Meteo'), findsOneWidget);
    expect(find.text('Début'), findsOneWidget);
    expect(find.text('Fin'), findsOneWidget);
    expect(find.textContaining('Critère de déclenchement'), findsOneWidget);

    await tester.tap(find.text("J'ai compris"));
    await settle(tester);
    expect(find.text('Zone affectée'), findsNothing);
  });

  testWidgets(
    'la cloche ouvre l’alerte la plus grave puis « Toutes les alertes »',
    (tester) async {
      await pumpApp(tester, weather: upcomingStorm());
      await tester.tap(find.bySemanticsLabel('Alertes météo'));
      await settle(tester);
      expect(find.text('Zone affectée'), findsOneWidget);

      await tester.tap(find.text('Toutes les alertes'));
      await settle(tester);
      expect(find.text('Alertes météo'), findsOneWidget);
      expect(find.text('Nabeul · prochaines 48 heures'), findsOneWidget);
      expect(find.text('À venir'), findsOneWidget);
      expect(find.text('En cours'), findsNothing);
    },
  );

  testWidgets('US08 : la page liste les alertes de la plus grave à la moins '
      'grave', (tester) async {
    await pumpApp(tester, weather: activeStorm());
    await tester.tap(find.bySemanticsLabel('Alertes météo'));
    await settle(tester);
    await tester.tap(find.text('Toutes les alertes'));
    await settle(tester);

    expect(find.text('En cours'), findsOneWidget);
    final storm = tester.getTopLeft(find.text('Alerte orages violents').last);
    final wind = tester.getTopLeft(find.text('Vent fort').last);
    expect(storm.dy, lessThan(wind.dy));

    await tester.tap(find.text('Vent fort').last);
    await settle(tester);
    expect(find.text('Zone affectée'), findsOneWidget);
  });

  testWidgets('US09 : historique des alertes terminées depuis moins de 48 h', (
    tester,
  ) async {
    final history = MemoryAlertsHistoryStore();
    await history.save(defaultCity.id, [
      WeatherAlert(
        id: 'wind-yesterday',
        title: 'Vent fort d’hier',
        summary: 'Rafales à 70 km/h',
        zone: 'Nabeul et environs',
        source: alertSource,
        severity: AlertSeverity.vigilance,
        startsAt: DateTime(2026, 9, 26, 10),
        endsAt: DateTime(2026, 9, 26, 14),
        originalText: 'Rafales ≥ 60 km/h',
      ),
    ]);
    await pumpApp(
      tester,
      overrides: [alertsHistoryStoreProvider.overrideWithValue(history)],
    );
    await tester.tap(find.bySemanticsLabel('Alertes météo'));
    await settle(tester);

    expect(find.textContaining('Aucune alerte en cours'), findsOneWidget);
    expect(find.text('Historique (48 h)'), findsOneWidget);
    expect(find.text('Vent fort d’hier'), findsOneWidget);
  });

  testWidgets('le bouton Retour ferme la page des alertes', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Alertes météo'));
    await settle(tester);
    await tester.tap(find.byTooltip('Retour'));
    await settle(tester);
    expect(find.text('Ressenti'), findsOneWidget);
  });
}
