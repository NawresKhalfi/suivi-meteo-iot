import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/http_client_provider.dart';
import '../../cities/domain/city.dart';
import '../domain/forecast_bundle.dart';
import '../domain/weather_condition.dart';
import 'open_meteo_parser.dart';
import 'weather_cache_store.dart';

/// Température et condition actuelles d'une ville (liste « Mes villes »).
class CityCurrentWeather {
  const CityCurrentWeather({
    required this.temperature,
    required this.condition,
    required this.isDay,
  });

  final double temperature;
  final WeatherCondition condition;
  final bool isDay;
}

abstract interface class WeatherRepository {
  Future<ForecastBundle> fetchForecast(City city);

  Future<Map<String, CityCurrentWeather>> fetchCurrentForCities(
    List<City> cities,
  );
}

class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository(
    this._client,
    this._cache, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final http.Client _client;
  final WeatherCacheStore _cache;
  final DateTime Function() _clock;

  static const _host = 'api.open-meteo.com';

  /// Récupère les prévisions ; en cas d'échec réseau, renvoie la dernière
  /// donnée connue marquée « hors ligne » si elle existe.
  @override
  Future<ForecastBundle> fetchForecast(City city) async {
    final uri = Uri.https(_host, '/v1/forecast', {
      'latitude': '${city.latitude}',
      'longitude': '${city.longitude}',
      'timezone': 'auto',
      'forecast_days': '10',
      'current': OpenMeteoFields.current,
      'hourly': OpenMeteoFields.hourly,
      'daily': OpenMeteoFields.daily,
    });
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw ApiException('Open-Meteo a répondu ${response.statusCode}.');
      }
      final body = utf8.decode(response.bodyBytes);
      final fetchedAt = _clock();
      final bundle = parseOpenMeteoForecast(
        jsonDecode(body) as Map<String, dynamic>,
        city: city.name,
        fetchedAt: fetchedAt,
      );
      await _cache.save(
        city.id,
        CachedPayload(body: body, fetchedAt: fetchedAt),
      );
      return bundle;
    } on Object {
      final cached = _cache.read(city.id);
      if (cached == null) rethrow;
      return parseOpenMeteoForecast(
        jsonDecode(cached.body) as Map<String, dynamic>,
        city: city.name,
        fetchedAt: cached.fetchedAt,
        isOffline: true,
      );
    }
  }

  @override
  Future<Map<String, CityCurrentWeather>> fetchCurrentForCities(
    List<City> cities,
  ) async {
    if (cities.isEmpty) return const {};
    final uri = Uri.https(_host, '/v1/forecast', {
      'latitude': cities.map((c) => c.latitude).join(','),
      'longitude': cities.map((c) => c.longitude).join(','),
      'current': 'temperature_2m,weather_code,is_day',
      'timezone': 'auto',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw ApiException('Open-Meteo a répondu ${response.statusCode}.');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    // Une seule ville → objet ; plusieurs → liste dans le même ordre.
    final items = decoded is List ? decoded : [decoded];
    return {
      for (var i = 0; i < cities.length && i < items.length; i++)
        cities[i].id: _currentFrom(items[i] as Map<String, dynamic>),
    };
  }

  static CityCurrentWeather _currentFrom(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return CityCurrentWeather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      condition: conditionFromWmo((current['weather_code'] as num).toInt()),
      isDay: current['is_day'] == 1,
    );
  }
}
