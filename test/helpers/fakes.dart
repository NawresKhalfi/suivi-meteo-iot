import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meteo/core/network/http_client_provider.dart';
import 'package:meteo/features/air_quality/application/air_quality_controller.dart';
import 'package:meteo/features/air_quality/data/air_quality_repository.dart';
import 'package:meteo/features/air_quality/domain/air_quality_snapshot.dart';
import 'package:meteo/features/alerts/application/alerts_controller.dart';
import 'package:meteo/features/alerts/data/hazard_repository.dart';
import 'package:meteo/features/alerts/domain/hazard_event.dart';
import 'package:meteo/features/cities/application/cities_controller.dart';
import 'package:meteo/features/cities/data/cities_store.dart';
import 'package:meteo/features/cities/data/city_search_repository.dart';
import 'package:meteo/features/cities/data/location_repository.dart';
import 'package:meteo/features/cities/domain/city.dart';
import 'package:meteo/features/map/application/map_controller.dart';
import 'package:meteo/features/map/data/map_repositories.dart';
import 'package:meteo/features/map/domain/map_models.dart';
import 'package:meteo/features/map/presentation/screens/map_screen.dart';
import 'package:meteo/features/weather/application/weather_controller.dart';
import 'package:meteo/features/weather/data/open_meteo_parser.dart';
import 'package:meteo/features/weather/data/weather_repository.dart';
import 'package:meteo/features/weather/domain/forecast_bundle.dart';
import 'package:meteo/features/weather/domain/weather_condition.dart';

Map<String, dynamic> loadForecastJson() =>
    jsonDecode(File('test/fixtures/forecast_nabeul.json').readAsStringSync())
        as Map<String, dynamic>;

ForecastBundle loadBundle({String city = 'Nabeul'}) => parseOpenMeteoForecast(
  loadForecastJson(),
  city: city,
  fetchedAt: DateTime.now(),
);

class FakeWeatherRepository implements WeatherRepository {
  int forecastCalls = 0;
  bool fail = false;

  @override
  Future<ForecastBundle> fetchForecast(City city) async {
    forecastCalls++;
    if (fail) throw Exception('offline');
    return loadBundle(city: city.name);
  }

  @override
  Future<Map<String, CityCurrentWeather>> fetchCurrentForCities(
    List<City> cities,
  ) async => {
    for (final (i, city) in cities.indexed)
      city.id: CityCurrentWeather(
        temperature: 20.0 + i,
        condition: WeatherCondition.clear,
        isDay: true,
      ),
  };
}

class FakeAirQualityRepository implements AirQualityRepository {
  @override
  Future<AirQualitySnapshot> fetchCurrent(
    City city,
  ) async => AirQualitySnapshot(
    city: city.name,
    aqi: 42,
    updatedAt: DateTime(2026, 9, 27, 16),
    pollutants: const [
      PollutantReading(name: 'PM2.5', value: 9, unit: 'µg/m³', guideline: 15),
      PollutantReading(name: 'O3', value: 103, unit: 'µg/m³', guideline: 100),
    ],
  );
}

class FakeCitySearchRepository implements CitySearchRepository {
  @override
  Future<List<City>> search(String query) async => [
    const City(
      name: 'Sousse',
      country: 'Tunisie',
      region: 'Sousse',
      latitude: 35.8254,
      longitude: 10.637,
    ),
  ].where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
}

class FakeLocationRepository implements LocationRepository {
  @override
  Future<City> currentCity() async => const City(
    name: 'Hammam Sousse',
    country: 'Tunisie',
    region: 'Sousse',
    latitude: 35.8609,
    longitude: 10.6031,
  );
}

class FakeRadarRepository implements RadarRepository {
  @override
  Future<RadarFrames> fetchFrames() async => RadarFrames(
    host: 'https://example.test',
    frames: [
      for (var i = 0; i < 3; i++)
        RadarFrame(
          time: DateTime.utc(2026, 9, 27, 15, i * 10),
          path: '/v2/radar/$i',
        ),
    ],
  );
}

class FakeGridRepository implements WeatherGridRepository {
  @override
  Future<List<GridPoint>> fetchGrid(City center) async => [
    GridPoint(
      latitude: center.latitude,
      longitude: center.longitude,
      hours: [
        for (var i = 0; i < 3; i++)
          GridHour(
            time: DateTime(2026, 9, 27, 16 + i),
            temperature: 25.0 - i,
            windSpeed: 12,
            windDirection: 90,
            cloudCover: 40,
          ),
      ],
    ),
  ];
}

class FakeHazardRepository implements HazardRepository {
  FakeHazardRepository([this.events = const []]);

  final List<HazardEvent> events;

  @override
  Future<List<HazardEvent>> fetchCurrentEvents() async => events;
}

/// Tuile transparente 1×1 : aucune requête réseau dans les tests.
class BlankTileProvider extends TileProvider {
  static final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_png);
}

List<Override> testOverrides({
  FakeWeatherRepository? weather,
  CitiesStore? citiesStore,
}) => [
  httpClientProvider.overrideWithValue(
    MockClient((_) async => http.Response('{}', 404)),
  ),
  weatherRepositoryProvider.overrideWithValue(
    weather ?? FakeWeatherRepository(),
  ),
  airQualityRepositoryProvider.overrideWithValue(FakeAirQualityRepository()),
  citySearchRepositoryProvider.overrideWithValue(FakeCitySearchRepository()),
  locationRepositoryProvider.overrideWithValue(FakeLocationRepository()),
  radarRepositoryProvider.overrideWithValue(FakeRadarRepository()),
  hazardRepositoryProvider.overrideWithValue(FakeHazardRepository()),
  weatherGridRepositoryProvider.overrideWithValue(FakeGridRepository()),
  mapTileProviderProvider.overrideWithValue(BlankTileProvider()),
  if (citiesStore != null) citiesStoreProvider.overrideWithValue(citiesStore),
];
