import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/http_client_provider.dart';
import '../../cities/domain/city.dart';
import '../domain/map_models.dart';

abstract interface class RadarRepository {
  Future<RadarFrames> fetchFrames();
}

/// API publique RainViewer : images radar des 2 dernières heures.
class RainViewerRadarRepository implements RadarRepository {
  RainViewerRadarRepository(this._client);

  final http.Client _client;

  @override
  Future<RadarFrames> fetchFrames() async {
    final response = await _client.get(
      Uri.https('api.rainviewer.com', '/public/weather-maps.json'),
    );
    if (response.statusCode != 200) {
      throw const ApiException('Radar indisponible.');
    }
    return parseRainViewer(jsonDecode(response.body) as Map<String, dynamic>);
  }
}

RadarFrames parseRainViewer(Map<String, dynamic> json) {
  final radar = json['radar'] as Map<String, dynamic>? ?? const {};
  RadarFrame frame(Object? item, bool forecast) {
    final data = item as Map<String, dynamic>;
    return RadarFrame(
      time: DateTime.fromMillisecondsSinceEpoch(
        (data['time'] as num).toInt() * 1000,
        isUtc: true,
      ),
      path: data['path'] as String,
      isForecast: forecast,
    );
  }

  return RadarFrames(
    host: json['host'] as String? ?? 'https://tilecache.rainviewer.com',
    frames: [
      for (final item in radar['past'] as List<dynamic>? ?? const [])
        frame(item, false),
      for (final item in radar['nowcast'] as List<dynamic>? ?? const [])
        frame(item, true),
    ],
  );
}

abstract interface class WeatherGridRepository {
  Future<List<GridPoint>> fetchGrid(City center);
}

/// Grille 5×5 (pas de 0,5°) autour de la ville, prévisions sur 8 heures,
/// récupérée en un seul appel Open-Meteo multi-points.
class OpenMeteoWeatherGridRepository implements WeatherGridRepository {
  OpenMeteoWeatherGridRepository(this._client);

  final http.Client _client;

  static const size = 5;
  static const step = 0.5;
  static const hours = 8;

  @override
  Future<List<GridPoint>> fetchGrid(City center) async {
    final latitudes = <double>[];
    final longitudes = <double>[];
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        latitudes.add(center.latitude + (row - size ~/ 2) * step);
        longitudes.add(center.longitude + (col - size ~/ 2) * step);
      }
    }
    String join(List<double> values) =>
        values.map((v) => v.toStringAsFixed(3)).join(',');
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': join(latitudes),
      'longitude': join(longitudes),
      'hourly': 'temperature_2m,wind_speed_10m,wind_direction_10m,cloud_cover',
      'forecast_hours': '$hours',
      'timezone': 'auto',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw const ApiException('Couche météo indisponible.');
    }
    final decoded = jsonDecode(response.body);
    final items = decoded is List ? decoded : [decoded];
    return [
      for (var i = 0; i < items.length && i < latitudes.length; i++)
        _point(items[i] as Map<String, dynamic>, latitudes[i], longitudes[i]),
    ];
  }

  static GridPoint _point(Map<String, dynamic> json, double lat, double lon) {
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List<dynamic>;
    num at(String key, int i) => (hourly[key] as List<dynamic>)[i] as num? ?? 0;
    return GridPoint(
      latitude: lat,
      longitude: lon,
      hours: [
        for (var i = 0; i < times.length; i++)
          GridHour(
            time: DateTime.parse(times[i] as String),
            temperature: at('temperature_2m', i).toDouble(),
            windSpeed: at('wind_speed_10m', i).toDouble(),
            windDirection: at('wind_direction_10m', i).round(),
            cloudCover: at('cloud_cover', i).round(),
          ),
      ],
    );
  }
}
