import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/wind/presentation/screens/wind_forecast_screen.dart';

void main() {
  testWidgets('affiche la courbe du vent et le détail sélectionné', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WindForecastScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vent sur 10 jours'), findsOneWidget);
    expect(find.textContaining('km/h'), findsWidgets);
    expect(find.textContaining('Rafales'), findsOneWidget);
  });
}
