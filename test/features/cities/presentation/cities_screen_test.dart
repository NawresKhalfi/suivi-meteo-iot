import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meteo/features/cities/presentation/screens/cities_screen.dart';

void main() {
  testWidgets('affiche les villes et permet de filtrer', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CitiesScreen())),
    );
    await tester.pump();
    expect(find.text('Paris'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'par');
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('Aucune ville trouvée.'), findsNothing);
  });
}
