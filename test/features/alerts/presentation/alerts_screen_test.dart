import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/alerts/presentation/screens/alerts_screen.dart';

void main() {
  testWidgets('affiche les alertes et leur niveau', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AlertsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alertes en cours'), findsOneWidget);
    expect(find.text('Orages localisés'), findsOneWidget);
    expect(find.text('Danger'), findsOneWidget);
    expect(find.text('Historique des 48 dernières heures'), findsOneWidget);
    expect(find.text('Alertes push de ma zone'), findsOneWidget);
  });

  testWidgets('permet d activer les notifications', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AlertsScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      find.text('Vous recevrez les nouvelles alertes importantes.'),
      findsOneWidget,
    );
  });
}
