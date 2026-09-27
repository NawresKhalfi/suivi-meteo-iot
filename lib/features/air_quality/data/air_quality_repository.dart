import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/http_client_provider.dart';
import '../../cities/domain/city.dart';
import '../domain/air_quality_snapshot.dart';

abstract interface class AirQualityRepository {
  Future<AirQualitySnapshot> fetchCurrent(City city);
}

class OpenMeteoAirQualityRepository implements AirQualityRepository {
  OpenMeteoAirQualityRepository(this._client);

  final http.Client _client;

  @override
  Future<AirQualitySnapshot> fetchCurrent(City city) async {
    final uri = Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': '${city.latitude}',
      'longitude': '${city.longitude}',
      'current':
          'us_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone',
      'timezone': 'auto',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw const ApiException("Qualité de l'air indisponible.");
    }
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return parseAirQuality(json, city: city.name);
  }
}

AirQualitySnapshot parseAirQuality(
  Map<String, dynamic> json, {
  required String city,
}) {
  final current = json['current'] as Map<String, dynamic>;
  double value(String key) => (current[key] as num?)?.toDouble() ?? 0;
  return AirQualitySnapshot(
    city: city,
    aqi: (current['us_aqi'] as num?)?.round() ?? 0,
    updatedAt: DateTime.parse(current['time'] as String),
    // Valeurs guides OMS 2021 (24 h, O3 sur 8 h).
    pollutants: [
      PollutantReading(
        name: 'PM10',
        value: value('pm10'),
        unit: 'µg/m³',
        guideline: 45,
      ),
      PollutantReading(
        name: 'PM2.5',
        value: value('pm2_5'),
        unit: 'µg/m³',
        guideline: 15,
      ),
      PollutantReading(
        name: 'CO',
        value: value('carbon_monoxide') / 1000,
        unit: 'mg/m³',
        guideline: 4,
      ),
      PollutantReading(
        name: 'NO2',
        value: value('nitrogen_dioxide'),
        unit: 'µg/m³',
        guideline: 25,
      ),
      PollutantReading(
        name: 'SO2',
        value: value('sulphur_dioxide'),
        unit: 'µg/m³',
        guideline: 40,
      ),
      PollutantReading(
        name: 'O3',
        value: value('ozone'),
        unit: 'µg/m³',
        guideline: 100,
      ),
    ],
  );
}
