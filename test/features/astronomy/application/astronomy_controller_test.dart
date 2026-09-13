import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/astronomy/domain/astronomy_snapshot.dart';

void main() {
  test('calcule une phase lunaire dans le cycle connu', () {
    final phase = moonPhaseForDate(DateTime.utc(2000, 1, 6));

    expect(phase, MoonPhase.newMoon);
  });
}
