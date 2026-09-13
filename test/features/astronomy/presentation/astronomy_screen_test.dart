import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/astronomy/presentation/screens/astronomy_screen.dart';

void main() {
  testWidgets('affiche le cycle solaire et la phase lunaire', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AstronomyScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cycle du jour'), findsOneWidget);
    expect(find.textContaining('Lever'), findsOneWidget);
    expect(find.textContaining('Coucher'), findsOneWidget);
    expect(find.text('Phase lunaire du jour'), findsOneWidget);
  });
}
