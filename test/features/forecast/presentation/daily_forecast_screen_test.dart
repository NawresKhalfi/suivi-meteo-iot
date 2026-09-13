import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/forecast/presentation/screens/daily_forecast_screen.dart';

void main() {
  testWidgets('affiche les prévisions sur dix jours', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DailyForecastScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prévisions sur 10 jours'), findsOneWidget);
    expect(find.text("Aujourd'hui"), findsOneWidget);
    expect(find.textContaining('Pluie'), findsWidgets);
    expect(find.textContaining('Coucher'), findsWidgets);
  });
}
