import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/astronomy/domain/astronomy_snapshot.dart';

import '../../../helpers/fakes.dart';

AstronomySnapshot _at(int hour, [int minute = 0]) => AstronomySnapshot(
  sunrise: DateTime(2026, 9, 27, 6),
  sunset: DateTime(2026, 9, 27, 18),
  moonPhase: MoonPhase.fullMoon,
  observedAt: DateTime(2026, 9, 27, hour, minute),
);

void main() {
  group('US24 — cycle jour / nuit', () {
    test('durée du jour entre lever et coucher', () {
      expect(_at(12).dayLength, const Duration(hours: 12));
    });

    test('jour ou nuit selon l’heure d’observation', () {
      expect(_at(5).isDaytime, isFalse);
      expect(_at(12).isDaytime, isTrue);
      expect(_at(19).isDaytime, isFalse);
    });

    test('avancement de la journée borné entre 0 et 1', () {
      expect(_at(5).dayProgress, 0);
      expect(_at(9).dayProgress, 0.25);
      expect(_at(12).dayProgress, 0.5);
      expect(_at(23).dayProgress, 1);
    });

    test('déduit du bundle météo (fixture Nabeul)', () {
      final astronomy = loadBundle().astronomy;
      expect(astronomy.sunrise, DateTime(2026, 9, 27, 6, 8));
      expect(astronomy.sunset, DateTime(2026, 9, 27, 18, 6));
      expect(astronomy.dayLength, const Duration(hours: 11, minutes: 58));
      expect(astronomy.isDaytime, isTrue); // 16:15
    });
  });

  group('US25 — phase lunaire', () {
    test('phases connues depuis la nouvelle lune de référence', () {
      expect(moonPhaseForDate(DateTime.utc(2000, 1, 6)), MoonPhase.newMoon);
      expect(
        moonPhaseForDate(DateTime.utc(2000, 1, 13)),
        MoonPhase.waxingCrescent,
      );
      expect(
        moonPhaseForDate(DateTime.utc(2000, 1, 14)),
        MoonPhase.firstQuarter,
      );
      expect(moonPhaseForDate(DateTime.utc(2000, 1, 21)), MoonPhase.fullMoon);
      // Un cycle synodique (≈ 29,53 j) plus tard : nouvelle lune.
      expect(moonPhaseForDate(DateTime.utc(2000, 2, 5)), MoonPhase.newMoon);
    });

    test('chaque phase a un libellé et une icône', () {
      expect(MoonPhase.fullMoon.label, 'Pleine lune');
      expect(MoonPhase.fullMoon.icon, '🌕');
      expect(MoonPhase.lastQuarter.label, 'Dernier quartier');
      expect(MoonPhase.values.map((p) => p.icon).toSet(), hasLength(8));
      expect(MoonPhase.values.map((p) => p.label).toSet(), hasLength(8));
    });
  });
}
