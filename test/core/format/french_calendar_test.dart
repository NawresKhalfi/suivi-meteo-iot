import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/core/format/french_calendar.dart';

void main() {
  final today = DateTime(2026, 9, 27, 16, 15); // dimanche

  test('jours et mois abrégés en français', () {
    expect(FrenchCalendar.weekdayShort(today), 'Dim');
    expect(FrenchCalendar.weekdayShort(DateTime(2026, 9, 28)), 'Lun');
    expect(FrenchCalendar.dayMonth(today), '27 sept');
    expect(FrenchCalendar.dayMonth(DateTime(2026, 2, 1)), '1 févr');
    expect(FrenchCalendar.dayMonth(DateTime(2026, 8, 15)), '15 août');
  });

  test('jour relatif : aujourd’hui, demain puis nom du jour', () {
    expect(
      FrenchCalendar.relativeDay(DateTime(2026, 9, 27), today),
      "Aujourd'hui",
    );
    expect(
      FrenchCalendar.relativeDay(DateTime(2026, 9, 28, 23), today),
      'Demain',
    );
    expect(FrenchCalendar.relativeDay(DateTime(2026, 9, 29), today), 'Mar');
  });

  test('changement de mois et d’année', () {
    expect(
      FrenchCalendar.relativeDay(DateTime(2027, 1, 1), DateTime(2026, 12, 31)),
      'Demain',
    );
  });
}
