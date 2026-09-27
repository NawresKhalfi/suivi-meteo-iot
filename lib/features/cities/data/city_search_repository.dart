import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/http_client_provider.dart';
import '../domain/city.dart';

abstract interface class CitySearchRepository {
  Future<List<City>> search(String query);
}

/// Géocodage Open-Meteo (gratuit, sans clé) en français.
class OpenMeteoCitySearchRepository implements CitySearchRepository {
  OpenMeteoCitySearchRepository(this._client);

  final http.Client _client;

  @override
  Future<List<City>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': trimmed,
      'count': '10',
      'language': 'fr',
      'format': 'json',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw const ApiException('Recherche de ville indisponible.');
    }
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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
}
