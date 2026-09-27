import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/weather/data/open_meteo_parser.dart';
import 'package:meteo/features/weather/domain/weather_condition.dart';

import '../../../helpers/fakes.dart';

void main() {
  test('analyse les conditions actuelles', () {
    final bundle = loadBundle();
    final current = bundle.current;
    expect(current.city, 'Nabeul');
    expect(current.temperature, 25.5);
    expect(current.apparentTemperature, 25.1);
    expect(current.condition, WeatherCondition.cloudy);
    expect(current.humidity, 53);
    expect(current.pressure, 1019.3);
    expect(current.visibility, 40420);
    expect(current.elevation, 16);
    expect(current.windDirection, 'E');
    expect(current.observedAt, DateTime(2026, 9, 27, 16, 15));
    expect(current.isOffline, isFalse);
  });

  test("les heures démarrent à l'heure courante et couvrent 48 h", () {
    final bundle = loadBundle();
    expect(bundle.hourly.first.time, DateTime(2026, 9, 27, 16));
    expect(bundle.hourly, hasLength(48));
    expect(bundle.next24Hours, hasLength(24));
  });

  test('analyse 10 jours avec lever/coucher et humidité moyenne', () {
    final bundle = loadBundle();
    expect(bundle.daily, hasLength(10));
    final today = bundle.today;
    expect(today.maximumTemperature, 27.3);
    expect(today.minimumTemperature, 19.2);
    expect(today.sunset, DateTime(2026, 9, 27, 18, 6));
    expect(today.humidity, inInclusiveRange(1, 100));
    // Le 4 octobre est orageux (code 95) : foudre ≥ 50 %.
    expect(bundle.daily[7].condition, WeatherCondition.thunderstorm);
    expect(bundle.daily[7].lightningProbability, greaterThanOrEqualTo(50));
  });

  test('probabilités neige, verglas et foudre', () {
    expect(
      snowProbability(
        pop: 40,
        snowfall: 1.2,
        condition: WeatherCondition.cloudy,
      ),
      40,
    );
    expect(
      snowProbability(pop: 40, snowfall: 0, condition: WeatherCondition.rain),
      0,
    );
    expect(
      iceProbability(
        pop: 60,
        minimumTemperature: -2,
        precipitationSum: 3,
        condition: WeatherCondition.rain,
      ),
      30,
    );
    expect(
      lightningProbability(
        pop: 0,
        maxCape: 3000,
        condition: WeatherCondition.clear,
      ),
      0,
    );
    expect(
      lightningProbability(
        pop: 80,
        maxCape: 2500,
        condition: WeatherCondition.showers,
      ),
      80,
    );
  });

  test('tolère les valeurs nulles de l’API', () {
    final json = loadForecastJson();
    (json['current'] as Map<String, dynamic>)['uv_index'] = null;
    final hourly = json['hourly'] as Map<String, dynamic>;
    (hourly['precipitation_probability'] as List)[20] = null;
    final bundle = parseOpenMeteoForecast(
      json,
      city: 'X',
      fetchedAt: DateTime.now(),
    );
    expect(bundle.current.uvIndex, 0);
  });
}
