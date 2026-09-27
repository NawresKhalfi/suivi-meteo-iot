import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/forecast/domain/hourly_forecast.dart';
import 'package:meteo/features/forecast/presentation/widgets/hourly_panel.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

HourlyForecast _hour({required int code, required int probability}) =>
    HourlyForecast(
      time: DateTime(2026, 9, 27, 18),
      temperature: 1,
      weatherCode: code,
      isDay: true,
      precipitationProbability: probability,
      precipitation: 1,
      windSpeed: 10,
      windGust: 20,
      windDirectionDegrees: 0,
      humidity: 90,
    );

/// E03 à E06 — Prévisions 24 h, 10 jours, pluie et vent.
void main() {
  Future<void> openForecast(WidgetTester tester, [String? tab]) async {
    await pumpApp(tester);
    await openTab(tester, 'Prévisions');
    if (tab != null) {
      await tester.tap(find.text(tab));
      await settle(tester);
    }
  }

  testWidgets('US10 : liste heure par heure, en commençant par « Maint. »', (
    tester,
  ) async {
    await openForecast(tester);
    expect(find.text('Nabeul, Tunisie'), findsOneWidget);
    expect(find.text('Maint.'), findsOneWidget);
    expect(find.text('17h'), findsOneWidget);
    expect(find.text('26°'), findsWidgets);
  });

  testWidgets('US12 : vent, direction et rafales pour chaque heure', (
    tester,
  ) async {
    await openForecast(tester);
    expect(find.text('15 km/h E · rafales 34 km/h'), findsOneWidget);
  });

  testWidgets('US11 : pastille pluie, neige ou verglas avec probabilité', (
    tester,
  ) async {
    await pumpWidgetInApp(
      tester,
      Column(
        children: [
          PrecipitationChip(hour: _hour(code: 61, probability: 80)),
          PrecipitationChip(hour: _hour(code: 73, probability: 40)),
          PrecipitationChip(hour: _hour(code: 66, probability: 25)),
          PrecipitationChip(hour: _hour(code: 0, probability: 0)),
        ],
      ),
    );
    expect(find.text('80%'), findsOneWidget);
    expect(find.byTooltip('Pluie'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.byTooltip('Neige'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.byTooltip('Verglas'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('US13 : 10 jours avec jour relatif, date et min/max', (
    tester,
  ) async {
    await openForecast(tester, '10 jours');
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.text('27 sept'), findsOneWidget);
    expect(find.text('Demain'), findsOneWidget);
    expect(find.text('27°'), findsWidgets);
    expect(find.text('19°'), findsWidgets);
  });

  testWidgets('US14/US15 : toucher un jour déplie probabilités et soleil', (
    tester,
  ) async {
    await openForecast(tester, '10 jours');
    expect(find.text('Foudre'), findsNothing);

    await tester.tap(find.text("Aujourd'hui"));
    await settle(tester);
    for (final label in ['Pluie', 'Neige', 'Verglas', 'Foudre', 'Coucher']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('18:06'), findsOneWidget);
    expect(find.text('06:08'), findsOneWidget);

    await tester.tap(find.text("Aujourd'hui"));
    await settle(tester);
    expect(find.text('Foudre'), findsNothing);
  });

  testWidgets('US16 : graphique des probabilités, maximum sélectionné', (
    tester,
  ) async {
    await openForecast(tester, 'Pluie & vent');
    expect(find.text('Probabilité de pluie — 10 jours'), findsOneWidget);
    expect(
      find.textContaining('32% de risque de pluie', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '0% le 27 sept',
      ),
    );
    await settle(tester);
    expect(
      find.textContaining('0% de risque de pluie', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('US17 : le bouton Radar ouvre la carte sur les précipitations', (
    tester,
  ) async {
    await openForecast(tester, 'Pluie & vent');
    await tester.tap(find.text('Radar'));
    await settle(tester);
    expect(find.text('Carte radar'), findsOneWidget);
    expect(
      find.text('Radar des précipitations · 2 dernières heures'),
      findsOneWidget,
    );
  });

  testWidgets('US18 : courbe du vent avec vitesse, direction et rafales', (
    tester,
  ) async {
    await openForecast(tester, 'Pluie & vent');
    await scrollTo(
      tester,
      find.text('Vitesse et direction du vent — 10 jours'),
    );
    expect(find.textContaining('rafales', findRichText: true), findsOneWidget);
  });

  testWidgets('erreur de chargement : message et Réessayer', (tester) async {
    await pumpApp(tester, weather: FakeWeatherRepository()..fail = true);
    await openTab(tester, 'Prévisions');
    expect(find.text('Prévisions indisponibles.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
