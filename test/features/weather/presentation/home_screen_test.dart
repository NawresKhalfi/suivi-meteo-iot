import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

/// E01 — Météo locale en temps réel.
void main() {
  testWidgets('US01 : température, condition, max/min et ressenti', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Nabeul'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
    expect(find.text('Ciel couvert'), findsOneWidget);
    expect(find.textContaining('Max '), findsOneWidget);
    expect(find.text('Ressenti'), findsOneWidget);
  });

  testWidgets('US02 : vent, humidité et pression affichés', (tester) async {
    await pumpApp(tester);
    expect(find.text('Vent'), findsWidgets);
    expect(find.text('Humidité'), findsWidgets);
    expect(find.text('53%'), findsOneWidget);

    await scrollTo(tester, find.text('Pression'));
    expect(find.text('1019 hPa'), findsOneWidget);
  });

  testWidgets('US03 : visibilité, point de rosée et élévation', (tester) async {
    await pumpApp(tester);
    await scrollTo(tester, find.text('Élévation'));
    expect(find.text('Visibilité'), findsOneWidget);
    expect(find.text('40 km'), findsOneWidget);
    expect(find.text('Point de rosée'), findsOneWidget);
    expect(find.text('15°'), findsOneWidget);
    expect(find.text('Indice UV'), findsWidgets);
  });

  testWidgets("US04 : tirer pour actualiser relance l'appel météo", (
    tester,
  ) async {
    final weather = FakeWeatherRepository();
    await pumpApp(tester, weather: weather);
    expect(weather.forecastCalls, 1);

    await tester.fling(find.text('Ressenti'), const Offset(0, 400), 1000);
    await settle(tester);
    expect(weather.forecastCalls, 2);
    expect(find.text("Mis à jour à l'instant"), findsOneWidget);
  });

  testWidgets('US05 : hors connexion, la dernière donnée est signalée', (
    tester,
  ) async {
    await pumpApp(tester, weather: FakeWeatherRepository()..offline = true);
    expect(find.textContaining('Hors ligne · données de'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
  });

  testWidgets('sans données, « Réessayer » relance le chargement', (
    tester,
  ) async {
    final weather = FakeWeatherRepository()..fail = true;
    await pumpApp(tester, weather: weather);
    expect(find.textContaining('Météo indisponible pour Nabeul'), findsOne);

    weather.fail = false;
    await tester.tap(find.text('Réessayer'));
    await settle(tester);
    expect(find.text('Ressenti'), findsOneWidget);
  });

  testWidgets('toucher la ville ouvre le sélecteur de ville', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Nabeul'));
    await settle(tester);
    expect(find.text('Changer de ville'), findsOneWidget);
    expect(find.text('Gérer mes villes'), findsOneWidget);
  });
}
