import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../../core/network/http_client_provider.dart';
import '../domain/city.dart';

abstract interface class CitySearchRepository {
  Future<List<City>> search(String query);
}

/// Recherche mondiale combinant deux sources gratuites, sans clé :
/// - Open-Meteo (GeoNames) : noms exacts, résultats triés par population ;
/// - Photon (OpenStreetMap) : tolère les fautes de frappe
///   (« hammem sousse » → Hammam Sousse) et couvre les petites localités.
class OpenMeteoCitySearchRepository implements CitySearchRepository {
  OpenMeteoCitySearchRepository(this._client);

  final http.Client _client;

  static const _maxResults = 10;

  /// Deux résultats plus proches que cette distance sont considérés
  /// comme la même ville.
  static const _duplicateDistanceKm = 5.0;

  @override
  Future<List<City>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final responses = await Future.wait([
      _guard(_searchOpenMeteo(trimmed)),
      _guard(_searchPhoton(trimmed)),
    ]);
    final openMeteo = responses[0];
    final photon = responses[1];
    if (openMeteo == null && photon == null) {
      throw const ApiException('Recherche de ville indisponible.');
    }

    final merged = <City>[];
    for (final city in [...?openMeteo, ...?photon]) {
      final isDuplicate = merged.any(
        (other) => _distanceKm(city, other) < _duplicateDistanceKm,
      );
      if (!isDuplicate) merged.add(city);
      if (merged.length == _maxResults) break;
    }
    return merged;
  }

  /// Renvoie `null` si la source a échoué, pour que l'autre prenne le relais.
  Future<List<City>?> _guard(Future<List<City>> request) async {
    try {
      return await request;
    } on Object {
      return null;
    }
  }

  Future<List<City>> _searchOpenMeteo(String query) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '$_maxResults',
      'language': 'fr',
      'format': 'json',
    });
    final json = await _getJson(uri);
    final results = json['results'] as List<dynamic>? ?? const [];
    return results.map((item) {
      final data = item as Map<String, dynamic>;
      return City(
        name: data['name'] as String,
        country: data['country'] as String? ?? '',
        region: data['admin1'] as String?,
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  Future<List<City>> _searchPhoton(String query) async {
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'limit': '$_maxResults',
      'lang': 'fr',
      // Uniquement des lieux habités / zones administratives, pas des rues
      // ni des commerces.
      'layer': ['city', 'district', 'locality', 'county'],
    });
    final json = await _getJson(uri);
    final features = json['features'] as List<dynamic>? ?? const [];
    final cities = <City>[];
    for (final item in features) {
      final feature = item as Map<String, dynamic>;
      final props = feature['properties'] as Map<String, dynamic>;
      final coords =
          (feature['geometry'] as Map<String, dynamic>)['coordinates']
              as List<dynamic>;
      final name = props['name'] as String?;
      if (name == null) continue;
      cities.add(
        City(
          name: _stripPrefix(name, const ['Délégation ', 'Gouvernorat ']),
          country: props['country'] as String? ?? '',
          region: switch (props['state'] as String?) {
            final state? => _stripPrefix(state, const ['Gouvernorat ']),
            null => null,
          },
          latitude: (coords[1] as num).toDouble(),
          longitude: (coords[0] as num).toDouble(),
        ),
      );
    }
    return cities;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: const {'User-Agent': 'suivi-meteo-iot/1.0'},
    );
    if (response.statusCode != 200) {
      throw const ApiException('Recherche de ville indisponible.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  static String _stripPrefix(String value, List<String> prefixes) {
    for (final prefix in prefixes) {
      if (value.startsWith(prefix)) return value.substring(prefix.length);
    }
    return value;
  }

  static double _distanceKm(City a, City b) {
    const earthRadiusKm = 6371.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLon = rad(b.longitude - a.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }
}
