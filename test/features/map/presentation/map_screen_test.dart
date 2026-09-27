import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/map/presentation/screens/map_screen.dart';
import 'package:meteo/features/map/presentation/widgets/map_overlays.dart';

import '../../../helpers/pump_app.dart';

/// E08 — Carte radar météo.
void main() {
  Finder onMap(Finder finder) =>
      find.descendant(of: find.byType(MapScreen), matching: finder);

  Future<void> openMap(WidgetTester tester, [String? layer]) async {
    await pumpApp(tester);
    await openTab(tester, 'Carte');
    if (layer != null) {
      await tapVisible(tester, onMap(find.text(layer)));
    }
  }

  Finder frameDot(int index) => find
      .descendant(
        of: find.byType(RadarPanel),
        matching: find.byType(AnimatedContainer),
      )
      .at(index);

  testWidgets('US21 : carte dynamique centrée sur la ville, température', (
    tester,
  ) async {
    await openMap(tester);
    expect(find.text('Carte radar'), findsOneWidget);
    expect(find.text('Température autour de Nabeul'), findsOneWidget);
    expect(find.text('Maintenant'), findsOneWidget);
    expect(find.text('25°'), findsOneWidget); // point de grille
    expect(find.text('© OpenStreetMap · RainViewer · Open-Meteo'), findsOne);
  });

  testWidgets('US22 : sélection des couches vent, nuages et précipitations', (
    tester,
  ) async {
    await openMap(tester, 'Vent');
    expect(find.text('Vent moyen et direction autour de Nabeul'), findsOne);
    expect(onMap(find.text('12')), findsOneWidget);

    await tapVisible(tester, onMap(find.text('Nuages')));
    expect(find.text('Couverture nuageuse autour de Nabeul'), findsOneWidget);
    expect(onMap(find.text('40%')), findsOneWidget);

    await tapVisible(tester, onMap(find.text('Précipitations')));
    expect(
      find.text('Radar des précipitations · 2 dernières heures'),
      findsOneWidget,
    );
    expect(find.text('Maintenant'), findsOneWidget);
  });

  testWidgets('toucher une image de la frise affiche son horodatage', (
    tester,
  ) async {
    await openMap(tester, 'Précipitations');
    await tester.tap(frameDot(0));
    await settle(tester);
    expect(find.text('Il y a 20 min'), findsOneWidget);

    await openTab(tester, 'Carte');
    await tapVisible(tester, onMap(find.text('Température')));
    await tester.tap(frameDot(1));
    await settle(tester);
    expect(find.text('Prévision 17h'), findsOneWidget);
  });

  testWidgets("US23 : lecture puis pause de l'animation radar", (tester) async {
    await openMap(tester, 'Précipitations');
    expect(find.bySemanticsLabel('Lire l’animation'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Lire l’animation'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.bySemanticsLabel('Mettre en pause'), findsOneWidget);
    expect(find.text('Il y a 20 min'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Il y a 10 min'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Mettre en pause'));
    await settle(tester);
    expect(find.bySemanticsLabel('Lire l’animation'), findsOneWidget);
    expect(find.text('Il y a 10 min'), findsOneWidget);
  });

  testWidgets("l'aperçu radar de l'accueil ouvre la carte", (tester) async {
    await pumpApp(tester);
    await scrollTo(tester, find.text('Voir la carte en direct'));
    await tapVisible(tester, find.text('Voir la carte en direct'));
    expect(find.text('Carte radar'), findsOneWidget);
  });
}
