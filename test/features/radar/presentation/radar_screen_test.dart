import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/radar/presentation/screens/radar_screen.dart';

void main() {
  testWidgets('affiche la carte, les couches et le contrôle animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: RadarScreen(layer: 'rain')),
    );

    expect(find.text('Radar météo'), findsOneWidget);
    expect(find.text('Pluie'), findsOneWidget);
    expect(find.text('Température'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.tap(find.text('Vent'));
    await tester.pump();
    expect(find.text('Couche : Vent'), findsOneWidget);
  });
}
