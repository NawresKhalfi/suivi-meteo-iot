import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/cities/application/cities_controller.dart';
import 'package:meteo/features/cities/data/cities_store.dart';
import 'package:meteo/features/cities/domain/city.dart';

import '../../../helpers/pump_app.dart';

const paris = City(
  name: 'Paris',
  country: 'France',
  latitude: 48.8534,
  longitude: 2.3488,
);

/// E10 — Gestion des villes.
void main() {
  late MemoryCitiesStore store;

  setUp(() {
    store = MemoryCitiesStore(
      StoredCities(
        cities: const [defaultCity, paris],
        defaultCityId: defaultCity.id,
      ),
    );
  });

  Future<void> openCities(WidgetTester tester) async {
    await pumpApp(
      tester,
      overrides: [citiesStoreProvider.overrideWithValue(store)],
    );
    await openTab(tester, 'Villes');
  }

  testWidgets('liste des villes suivies avec leur météo actuelle', (
    tester,
  ) async {
    await openCities(tester);
    expect(find.text('Mes villes'), findsOneWidget);
    expect(find.text('Nabeul'), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('20°'), findsOneWidget);
    expect(find.text('21°'), findsOneWidget);
    expect(find.byTooltip('Ville par défaut'), findsOneWidget);
    expect(find.byTooltip('Définir par défaut'), findsOneWidget);
  });

  testWidgets('US26 : ajouter une ville depuis les suggestions', (
    tester,
  ) async {
    await openCities(tester);
    await tester.tap(find.byTooltip('Ajouter une ville'));
    await settle(tester);
    expect(find.text('Suggestions'), findsOneWidget);

    await tester.tap(find.text('Tunis'));
    await settle(tester);
    expect(find.text('Tunis a été ajoutée à vos villes'), findsOneWidget);
    expect(store.value.cities.map((c) => c.name), contains('Tunis'));
  });

  testWidgets('US26 : une ville déjà suivie n’est pas ajoutée deux fois', (
    tester,
  ) async {
    await openCities(tester);
    await tester.tap(find.byTooltip('Ajouter une ville'));
    await settle(tester);
    await tester.tap(find.text('Paris').last);
    await settle(tester);
    expect(find.text('Paris est déjà dans vos villes'), findsOneWidget);
    expect(store.value.cities, hasLength(2));
  });

  testWidgets('US26 : recherche sans résultat', (tester) async {
    await openCities(tester);
    await tester.tap(find.byTooltip('Ajouter une ville'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    expect(find.text('Aucune ville trouvée'), findsOneWidget);
  });

  testWidgets('US27 : toucher une ville la sélectionne et ouvre l’accueil', (
    tester,
  ) async {
    await openCities(tester);
    await tester.tap(find.text('Paris'));
    await settle(tester);
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('Ressenti'), findsOneWidget);
  });

  testWidgets("US27 : changer de ville depuis l'accueil", (tester) async {
    await pumpApp(
      tester,
      overrides: [citiesStoreProvider.overrideWithValue(store)],
    );
    await tester.tap(find.text('Nabeul'));
    await settle(tester);
    await tester.tap(find.text('Paris'));
    await settle(tester);
    expect(find.text('Ville sélectionnée : Paris'), findsOneWidget);
    expect(find.text('Paris'), findsWidgets);

    await tester.tap(find.text('Paris').first);
    await settle(tester);
    await tester.tap(find.text('Gérer mes villes'));
    await settle(tester);
    expect(find.text('Mes villes'), findsOneWidget);
  });

  testWidgets('US28 : définir une ville favorite par défaut', (tester) async {
    await openCities(tester);
    await tester.tap(find.byTooltip('Définir par défaut'));
    await settle(tester);
    expect(find.text('Paris est votre ville par défaut'), findsOneWidget);
    expect(store.value.defaultCityId, paris.id);
    expect(find.byTooltip('Définir par défaut'), findsOneWidget); // Nabeul
  });

  testWidgets('US29 : supprimer une ville après confirmation', (tester) async {
    await openCities(tester);
    await tester.tap(find.byTooltip('Supprimer').last);
    await settle(tester);
    expect(find.text('Supprimer cette ville ?'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await settle(tester);
    expect(store.value.cities, hasLength(2));

    await tester.tap(find.byTooltip('Supprimer').last);
    await settle(tester);
    await tester.tap(find.text('Supprimer'));
    await settle(tester);
    expect(find.text('Paris a été supprimée'), findsOneWidget);
    expect(store.value.cities, [defaultCity]);
    expect(find.text('Paris'), findsNothing);
  });
}
