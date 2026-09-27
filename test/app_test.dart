import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/settings/application/home_screen_widget_controller.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('accueil : météo réelle de la ville par défaut', (tester) async {
    await pumpApp(tester);
    expect(find.text('Nabeul'), findsOneWidget);
    expect(find.text('26'), findsOneWidget); // 25,5 °C arrondi
    expect(find.text('Ciel couvert'), findsOneWidget);
    expect(find.text('Ressenti'), findsOneWidget);
    expect(find.text("Aujourd'hui"), findsWidgets);
    expect(find.text('Maint.'), findsOneWidget);
    expect(find.text('42 · Bon'), findsOneWidget);
    expect(find.text('Coucher du soleil'), findsOneWidget);
    expect(find.text('18:06'), findsOneWidget);
  });

  testWidgets('erreur réseau sans cache : message et bouton Réessayer', (
    tester,
  ) async {
    await pumpApp(tester, weather: FakeWeatherRepository()..fail = true);
    expect(find.textContaining('Météo indisponible'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('navigue entre les 5 onglets', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Prévisions'));
    await settle(tester);
    expect(find.text('24 heures'), findsOneWidget);
    await tester.tap(find.text('10 jours'));
    await settle(tester);
    expect(find.text('27 sept'), findsOneWidget);
    await tester.tap(find.text('Pluie & vent'));
    await settle(tester);
    expect(find.text('Probabilité de pluie — 10 jours'), findsOneWidget);

    await tester.tap(find.text('Carte'));
    await settle(tester);
    expect(find.text('Carte radar'), findsOneWidget);
    await tester.tap(find.text('Précipitations'));
    await settle(tester);
    expect(find.text('Maintenant'), findsOneWidget);

    await tester.tap(find.text('Villes'));
    await settle(tester);
    expect(find.text('Mes villes'), findsOneWidget);

    await tester.tap(find.text('Réglages'));
    await settle(tester);
    expect(find.text('Unités de mesure'), findsOneWidget);
  });

  testWidgets("« 10 jours » depuis l'accueil ouvre l'onglet correspondant", (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.ensureVisible(find.text('10 jours'));
    await settle(tester);
    await tester.tap(find.text('10 jours'));
    await settle(tester);
    expect(find.text('Prévisions'), findsWidgets);
    expect(find.text('27 sept'), findsOneWidget);
  });

  testWidgets('changer d’unité de température met à jour l’accueil', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Réglages'));
    await settle(tester);
    await tester.tap(find.text('Température'));
    await settle(tester);
    await tester.tap(find.text('Fahrenheit (°F)'));
    await settle(tester);
    expect(find.text('Fahrenheit (°F)'), findsOneWidget);

    await tester.tap(find.text('Accueil'));
    await settle(tester);
    expect(find.text('78'), findsOneWidget); // 25,5 °C = 77,9 °F
  });

  testWidgets('ajoute une ville via la recherche puis la sélectionne', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Villes'));
    await settle(tester);
    await tester.tap(find.byTooltip('Ajouter une ville'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'sous');
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    await tester.tap(find.text('Sousse').last);
    await settle(tester);
    expect(find.text('Sousse a été ajoutée à vos villes'), findsOneWidget);

    await tester.tap(find.text('Sousse'));
    await settle(tester);
    expect(find.text('Sousse'), findsOneWidget); // accueil
    expect(find.text('Ressenti'), findsOneWidget);
  });

  testWidgets('mesure localisée : ajoute la position comme ville par défaut', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Villes'));
    await settle(tester);
    await tester.tap(find.text('Mesure localisée'));
    await settle(tester);
    expect(find.text('Partager votre position ?'), findsOneWidget);
    await tester.tap(find.text('Partager ma position'));
    await settle(tester);
    expect(
      find.text('Hammam Sousse est votre ville par défaut'),
      findsOneWidget,
    );
    expect(find.text('Hammam Sousse'), findsOneWidget);
  });

  testWidgets('la ville par défaut ne peut pas être supprimée', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Villes'));
    await settle(tester);
    await tester.tap(find.byTooltip('Supprimer'));
    await settle(tester);
    expect(
      find.text(
        'Choisissez une autre ville par défaut avant de supprimer celle-ci',
      ),
      findsOneWidget,
    );
  });

  testWidgets("la cloche ouvre la page d'alertes quand tout est calme", (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Alertes météo'));
    await settle(tester);
    expect(find.textContaining('Aucune alerte en cours'), findsOneWidget);
  });

  testWidgets("le widget d'écran d'accueil s'ajoute après acceptation", (
    tester,
  ) async {
    final widget = FakeHomeScreenWidgetService();
    await pumpApp(
      tester,
      overrides: [homeScreenWidgetServiceProvider.overrideWithValue(widget)],
    );
    // L'app ouverte sur la ville par défaut alimente déjà le widget.
    expect(widget.updates.last.city, 'Nabeul');
    expect(widget.updates.last.temperature, '26°');

    await tester.tap(find.text('Réglages'));
    await settle(tester);
    final hint = find.text("Toucher pour l'ajouter à l'écran d'accueil");
    await tester.scrollUntilVisible(hint, 200);
    await tester.ensureVisible(hint);
    await settle(tester);
    await tester.tap(hint);
    await settle(tester);
    expect(
      find.text("Ajouter le widget à l'écran d'accueil ?"),
      findsOneWidget,
    );

    await tester.tap(find.text('Pas maintenant'));
    await settle(tester);
    expect(widget.pinRequests, 0);

    await tester.tap(hint);
    await settle(tester);
    await tester.tap(find.text('Ajouter'));
    await settle(tester);
    expect(widget.pinRequests, 1);
    expect(find.text("Ajouter le widget à l'écran d'accueil ?"), findsNothing);
  });

  testWidgets("sans épinglage possible, le dialogue explique quoi faire", (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Réglages'));
    await settle(tester);
    final hint = find.text("Toucher pour l'ajouter à l'écran d'accueil");
    await tester.scrollUntilVisible(hint, 200);
    await tester.ensureVisible(hint);
    await settle(tester);
    await tester.tap(hint);
    await settle(tester);
    expect(find.text('Widget météo'), findsOneWidget);
    await tester.tap(find.text("J'ai compris"));
    await settle(tester);
    expect(find.text('Widget météo'), findsNothing);
  });
}
