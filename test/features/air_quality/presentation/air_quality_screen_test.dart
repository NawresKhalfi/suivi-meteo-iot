import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/air_quality/presentation/screens/air_quality_screen.dart';

void main() {
  testWidgets('affiche le niveau et les polluants', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AirQualityScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text("Qualité de l'air"), findsOneWidget);
    expect(find.text('Bon'), findsOneWidget);
    expect(find.text('PM10'), findsOneWidget);
    expect(find.text('PM2.5'), findsOneWidget);
    expect(find.text('O3'), findsOneWidget);
  });
}
