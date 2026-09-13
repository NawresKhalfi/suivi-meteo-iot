import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/forecast/presentation/screens/rain_probability_screen.dart';

void main() {
  testWidgets('affiche le graphique des probabilités et le radar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RainProbabilityScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tendance des précipitations'), findsOneWidget);
    expect(find.textContaining('%'), findsWidgets);
    expect(find.text('Voir le radar de pluie'), findsOneWidget);
  });
}
