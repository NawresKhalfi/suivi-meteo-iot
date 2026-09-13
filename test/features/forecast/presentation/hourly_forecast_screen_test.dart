import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/forecast/presentation/screens/hourly_forecast_screen.dart';

void main() {
  testWidgets('affiche les prévisions horaires', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HourlyForecastScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prévisions sur 24 heures'), findsOneWidget);
    expect(find.text('Maint.'), findsOneWidget);
    expect(find.textContaining('Pluie'), findsWidgets);
    expect(find.textContaining('raf.'), findsWidgets);
  });
}
