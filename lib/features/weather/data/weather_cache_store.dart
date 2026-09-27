import 'dart:convert';

import '../../../core/storage/local_preferences.dart';

class CachedPayload {
  const CachedPayload({required this.body, required this.fetchedAt});

  final String body;
  final DateTime fetchedAt;
}

/// Mémorise la dernière réponse brute par ville (E01 – US05, hors ligne).
abstract interface class WeatherCacheStore {
  CachedPayload? read(String cityId);
  Future<void> save(String cityId, CachedPayload payload);
}

class SharedPreferencesWeatherCacheStore implements WeatherCacheStore {
  SharedPreferencesWeatherCacheStore(this._preferences);

  final LocalPreferences _preferences;

  @override
  CachedPayload? read(String cityId) {
    final value = _preferences.weatherCache(cityId);
    if (value == null) return null;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return CachedPayload(
        body: json['body'] as String,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(String cityId, CachedPayload payload) =>
      _preferences.saveWeatherCache(
        cityId,
        jsonEncode({
          'body': payload.body,
          'fetchedAt': payload.fetchedAt.toIso8601String(),
        }),
      );
}

class MemoryWeatherCacheStore implements WeatherCacheStore {
  final Map<String, CachedPayload> values = {};

  @override
  CachedPayload? read(String cityId) => values[cityId];

  @override
  Future<void> save(String cityId, CachedPayload payload) async =>
      values[cityId] = payload;
}
