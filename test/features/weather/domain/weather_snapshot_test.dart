import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/settings/domain/unit_formatter.dart';
import 'package:meteo/features/settings/domain/unit_settings.dart';
import 'package:meteo/features/weather/domain/weather_snapshot.dart';
import 'package:meteo/features/weather/presentation/widgets/home_hero.dart';

import '../../../helpers/fakes.dart';

void main() {
  const format = UnitFormatter(UnitSettings());

  test('conditions actuelles complètes (US01 à US03)', () {
    final current = loadBundle().current;
    expect(current.temperature, 25.5);
    expect(current.apparentTemperature, 25.1);
    expect(current.humidity, 53);
    expect(current.pressure, 1019.3);
    expect(current.dewPoint, 15.2);
    expect(current.visibility, 40420);
    expect(current.windDirection, 'E'); // 83°
    expect(current.isOffline, isFalse);
  });

  test('niveaux et conseils UV', () {
    expect(uvLevelLabel(0), 'Faible');
    expect(uvLevelLabel(2.9), 'Faible');
    expect(uvLevelLabel(3), 'Modéré');
    expect(uvLevelLabel(6), 'Élevé');
    expect(uvLevelLabel(8), 'Très élevé');
    expect(uvLevelLabel(11), 'Extrême');
    expect(uvAdvice(1), 'Aucune protection nécessaire');
    expect(uvAdvice(4), 'Protection conseillée');
    expect(uvAdvice(7), 'Chapeau et crème solaire');
    expect(uvAdvice(9), 'Évitez le soleil entre 12h et 16h');
  });

  test("libellé d'actualisation : à l'instant ou hors ligne (US04, US05)", () {
    expect(updatedLabel(loadBundle(), format.time), "Mis à jour à l'instant");
    final offline = loadBundle(isOffline: true);
    expect(
      updatedLabel(offline, format.time),
      startsWith('Hors ligne · données de '),
    );
  });
}
