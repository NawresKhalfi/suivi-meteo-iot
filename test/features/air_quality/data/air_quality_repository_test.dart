import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meteo/core/network/http_client_provider.dart';
import 'package:meteo/features/air_quality/data/air_quality_repository.dart';
import 'package:meteo/features/air_quality/domain/air_quality_snapshot.dart';
import 'package:meteo/features/cities/domain/city.dart';

const _response = {
  'current': {
    'time': '2026-09-27T16:00',
    'us_aqi': 57.4,
    'pm10': 30.2,
    'pm2_5': 12.5,
    'carbon_monoxide': 210.0,
    'nitrogen_dioxide': 8.1,
    'sulphur_dioxide': 2.3,
    'ozone': 110.0,
  },
};

void main() {
  group('US19 — niveau global', () {
    test('seuils de l’indice US AQI', () {
      expect(airQualityLevelForAqi(0), AirQualityLevel.good);
      expect(airQualityLevelForAqi(50), AirQualityLevel.good);
      expect(airQualityLevelForAqi(51), AirQualityLevel.moderate);
      expect(airQualityLevelForAqi(101), AirQualityLevel.unhealthySensitive);
      expect(airQualityLevelForAqi(151), AirQualityLevel.unhealthy);
      expect(airQualityLevelForAqi(201), AirQualityLevel.veryUnhealthy);
      expect(airQualityLevelForAqi(301), AirQualityLevel.hazardous);
    });

    test('libellés et conseils en français', () {
      expect(AirQualityLevel.good.label, 'Bon');
      expect(AirQualityLevel.moderate.label, 'Modéré');
      expect(AirQualityLevel.hazardous.label, 'Dangereux');
      for (final level in AirQualityLevel.values) {
        expect(level.advice, isNotEmpty);
      }
    });
  });

  group('US20 — six polluants', () {
    test('analyse la réponse Open-Meteo', () {
      final snapshot = parseAirQuality(_response, city: 'Nabeul');
      expect(snapshot.city, 'Nabeul');
      expect(snapshot.aqi, 57);
      expect(snapshot.level, AirQualityLevel.moderate);
      expect(snapshot.updatedAt, DateTime(2026, 9, 27, 16));
      expect(snapshot.pollutants.map((p) => p.name), [
        'PM10',
        'PM2.5',
        'CO',
        'NO2',
        'SO2',
        'O3',
      ]);
      // Le CO est converti de µg/m³ en mg/m³.
      expect(snapshot.pollutant('CO')!.value, closeTo(0.21, 1e-9));
      expect(snapshot.pollutant('CO')!.unit, 'mg/m³');
      expect(snapshot.pollutant('XYZ'), isNull);
    });

    test('ratio par rapport à la valeur guide OMS', () {
      final snapshot = parseAirQuality(_response, city: 'Nabeul');
      expect(snapshot.pollutant('O3')!.ratio, closeTo(1.1, 1e-9));
      expect(snapshot.pollutant('PM2.5')!.ratio, closeTo(12.5 / 15, 1e-9));
      const zero = PollutantReading(
        name: 'X',
        value: 5,
        unit: '',
        guideline: 0,
      );
      expect(zero.ratio, 0);
    });

    test('valeurs manquantes remplacées par 0', () {
      final snapshot = parseAirQuality({
        'current': {'time': '2026-09-27T16:00'},
      }, city: 'Nabeul');
      expect(snapshot.aqi, 0);
      expect(snapshot.pollutant('PM10')!.value, 0);
    });
  });

  group('OpenMeteoAirQualityRepository', () {
    test('interroge l’API avec les coordonnées de la ville', () async {
      late Uri requested;
      final repository = OpenMeteoAirQualityRepository(
        MockClient((request) async {
          requested = request.url;
          return http.Response.bytes(utf8.encode(jsonEncode(_response)), 200);
        }),
      );
      final snapshot = await repository.fetchCurrent(defaultCity);
      expect(requested.host, 'air-quality-api.open-meteo.com');
      expect(requested.queryParameters['latitude'], '36.4561');
      expect(requested.queryParameters['current'], contains('us_aqi'));
      expect(snapshot.city, 'Nabeul');
    });

    test('erreur serveur : ApiException', () {
      final repository = OpenMeteoAirQualityRepository(
        MockClient((_) async => http.Response('', 503)),
      );
      expect(
        repository.fetchCurrent(defaultCity),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
