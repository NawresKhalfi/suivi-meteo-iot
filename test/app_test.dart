import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('affiche le tableau de bord météo', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MeteoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('21.8 °C'), findsOneWidget);
    expect(find.text('Humidité'), findsOneWidget);
  });
}
