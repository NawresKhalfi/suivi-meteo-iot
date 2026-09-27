import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meteo/features/cities/domain/city.dart';
import 'package:meteo/features/weather/data/weather_cache_store.dart';
import 'package:meteo/features/weather/data/weather_repository.dart';

void main() {
  final body = File('test/fixtures/forecast_nabeul.json').readAsStringSync();

  test('interroge Open-Meteo avec les coordonnées de la ville', () async {
    late Uri requested;
    final repository = OpenMeteoWeatherRepository(
      MockClient((request) async {
        requested = request.url;
        return http.Response.bytes(utf8.encode(body), 200);
      }),
      MemoryWeatherCacheStore(),
    );
    final bundle = await repository.fetchForecast(defaultCity);
    expect(requested.host, 'api.open-meteo.com');
    expect(requested.queryParameters['latitude'], '36.4561');
    expect(requested.queryParameters['forecast_days'], '10');
    expect(bundle.current.city, 'Nabeul');
  });

  test('renvoie la dernière donnée connue hors connexion (US05)', () async {
    final cache = MemoryWeatherCacheStore();
    var online = true;
    final repository = OpenMeteoWeatherRepository(
      MockClient((_) async {
        if (!online) throw const SocketException('offline');
        return http.Response.bytes(utf8.encode(body), 200);
      }),
      cache,
    );
    await repository.fetchForecast(defaultCity);
    online = false;
    final offline = await repository.fetchForecast(defaultCity);
    expect(offline.current.isOffline, isTrue);
    expect(offline.current.temperature, 25.5);
  });

  test('propage l’erreur sans cache', () {
    final repository = OpenMeteoWeatherRepository(
      MockClient((_) async => http.Response('', 500)),
      MemoryWeatherCacheStore(),
    );
    expect(repository.fetchForecast(defaultCity), throwsA(anything));
  });

  test('météo actuelle de plusieurs villes en un appel', () async {
    const paris = City(
      name: 'Paris',
      country: 'France',
      latitude: 48.85,
      longitude: 2.35,
    );
    final repository = OpenMeteoWeatherRepository(
      MockClient((request) async {
        expect(request.url.queryParameters['latitude'], '36.4561,48.85');
        return http.Response(
          jsonEncode([
            {
              'current': {
                'temperature_2m': 25.5,
                'weather_code': 3,
                'is_day': 1,
              },
            },
            {
              'current': {
                'temperature_2m': 14.1,
                'weather_code': 61,
                'is_day': 0,
              },
            },
          ]),
          200,
        );
      }),
      MemoryWeatherCacheStore(),
    );
    final result = await repository.fetchCurrentForCities([defaultCity, paris]);
    expect(result[paris.id]!.temperature, 14.1);
    expect(result[defaultCity.id]!.isDay, isTrue);
  });
}
