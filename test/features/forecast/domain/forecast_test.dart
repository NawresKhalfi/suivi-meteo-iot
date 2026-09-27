import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/forecast/application/forecast_tab_controller.dart';
import 'package:meteo/features/weather/domain/weather_condition.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('E03 — prévisions 24 heures', () {
    test('US10 : 24 heures consécutives à partir de l’heure courante', () {
      final hours = loadBundle().next24Hours;
      expect(hours, hasLength(24));
      expect(hours.first.time, DateTime(2026, 9, 27, 16));
      for (var i = 1; i < hours.length; i++) {
        expect(hours[i].time.difference(hours[i - 1].time).inHours, 1);
      }
    });

    test('US11 : type de précipitation déduit de la condition', () {
      final rain = loadBundle(
        json: patchedForecastJson({'weather_code': 61}),
      ).hourly.firstWhere((h) => h.time.hour == 18);
      expect(rain.precipitationType, PrecipitationType.rain);

      final snow = loadBundle(
        json: patchedForecastJson({'weather_code': 73}),
      ).hourly.firstWhere((h) => h.time.hour == 18);
      expect(snow.precipitationType, PrecipitationType.snow);

      final ice = loadBundle(
        json: patchedForecastJson({'weather_code': 66}),
      ).hourly.firstWhere((h) => h.time.hour == 18);
      expect(ice.precipitationType, PrecipitationType.ice);
    });

    test('US12 : vent, rafales et direction heure par heure', () {
      final hour = loadBundle().hourly.first;
      expect(hour.windSpeed, 15.2);
      expect(hour.windGust, 33.5);
      expect(hour.windDirectionDegrees, 83);
      expect(hour.windDirection, 'E');
    });
  });

  group('E04 à E06 — prévisions 10 jours', () {
    test('US13 : 10 jours à partir d’aujourd’hui avec min/max', () {
      final daily = loadBundle().daily;
      expect(daily, hasLength(10));
      expect(daily.first.date, DateTime(2026, 9, 27));
      expect(daily.first.maximumTemperature, 27.3);
      expect(daily.first.minimumTemperature, 19.2);
      expect(daily.first.condition, WeatherCondition.cloudy);
    });

    test('US15 : heure du coucher du soleil', () {
      final today = loadBundle().today;
      expect(today.sunset, DateTime(2026, 9, 27, 18, 6));
      expect(today.sunrise, DateTime(2026, 9, 27, 6, 8));
    });

    test('US16 : probabilités de pluie des 10 jours', () {
      final probabilities = loadBundle().daily.map((d) => d.rainProbability);
      expect(probabilities, [0, 5, 15, 0, 4, 9, 18, 32, 25, 31]);
    });

    test('US18 : vitesse, rafales et direction dominante du vent', () {
      final today = loadBundle().today;
      expect(today.windSpeed, 16.5);
      expect(today.windGust, 34.6);
      expect(today.windDirection, 'NE'); // 33°
    });
  });

  group('ForecastTabController', () {
    test('démarre sur « 24 heures » et change d’onglet', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(forecastTabProvider), ForecastTab.hours24);

      container.read(forecastTabProvider.notifier).select(ForecastTab.days10);
      expect(container.read(forecastTabProvider), ForecastTab.days10);
      expect(ForecastTab.values.map((t) => t.label), [
        '24 heures',
        '10 jours',
        'Pluie & vent',
      ]);
    });
  });
}
