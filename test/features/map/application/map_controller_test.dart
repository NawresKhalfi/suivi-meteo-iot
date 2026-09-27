import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meteo/core/network/http_client_provider.dart';
import 'package:meteo/features/cities/domain/city.dart';
import 'package:meteo/features/map/application/map_controller.dart';
import 'package:meteo/features/map/data/map_repositories.dart';
import 'package:meteo/features/map/domain/map_models.dart';

import '../../../helpers/fakes.dart';

Map<String, dynamic> _gridPoint(double temperature) => {
  'hourly': {
    'time': ['2026-09-27T16:00', '2026-09-27T17:00'],
    'temperature_2m': [temperature, temperature - 1],
    'wind_speed_10m': [12.4, null],
    'wind_direction_10m': [90.4, 180],
    'cloud_cover': [40, 60],
  },
};

void main() {
  group('MapViewController (US21 à US23)', () {
    late ProviderContainer container;
    MapViewController controller() =>
        container.read(mapViewControllerProvider.notifier);
    MapViewState state() => container.read(mapViewControllerProvider);

    setUp(() async {
      container = ProviderContainer(overrides: testOverrides());
      container.listen(mapViewControllerProvider, (_, _) {});
      await container.read(radarFramesProvider.future);
      await container.read(weatherGridProvider.future);
    });
    tearDown(() => container.dispose());

    test('démarre sur la couche température, image « Maintenant »', () {
      expect(state().layer, MapLayer.temperature);
      expect(state().frameIndex, isNull);
      expect(state().isPlaying, isFalse);
      expect(controller().currentIndex, 0);
      expect(controller().frameCount, 3); // heures de la grille
    });

    test('US22 : changer de couche revient à « Maintenant »', () {
      controller().selectFrame(2);
      controller().selectLayer(MapLayer.precipitation);
      expect(state().layer, MapLayer.precipitation);
      expect(state().frameIndex, isNull);
      expect(controller().frameCount, 3); // images radar
      expect(controller().currentIndex, 2); // dernière image observée
    });

    test('sélectionner une image arrête l’animation', () {
      controller().selectLayer(MapLayer.precipitation);
      controller().togglePlay();
      controller().selectFrame(1);
      expect(state().frameIndex, 1);
      expect(state().isPlaying, isFalse);
    });

    testWidgets('US23 : lecture en boucle toutes les 700 ms puis pause', (
      tester,
    ) async {
      controller().selectLayer(MapLayer.precipitation);
      controller().togglePlay();
      expect(state().isPlaying, isTrue);
      expect(controller().currentIndex, 0); // repart de la plus ancienne

      await tester.pump(const Duration(milliseconds: 700));
      expect(controller().currentIndex, 1);
      await tester.pump(const Duration(milliseconds: 700));
      expect(controller().currentIndex, 2);
      await tester.pump(const Duration(milliseconds: 700));
      expect(controller().currentIndex, 0);

      controller().togglePlay();
      expect(state().isPlaying, isFalse);
      await tester.pump(const Duration(milliseconds: 1400));
      expect(controller().currentIndex, 0);
    });
  });

  group('RadarFrames', () {
    test('sans image observée, « Maintenant » est la première', () {
      final frames = RadarFrames(
        host: 'https://example.test',
        frames: [
          RadarFrame(
            time: DateTime.utc(2026, 9, 27, 15),
            path: '/a',
            isForecast: true,
          ),
        ],
      );
      expect(frames.nowIndex, 0);
    });
  });

  group('OpenMeteoWeatherGridRepository', () {
    test(
      'US21 : grille 5×5 autour de la ville, analysée point par point',
      () async {
        late Uri requested;
        final repository = OpenMeteoWeatherGridRepository(
          MockClient((request) async {
            requested = request.url;
            return http.Response(
              jsonEncode([for (var i = 0; i < 25; i++) _gridPoint(20.0 + i)]),
              200,
            );
          }),
        );
        final points = await repository.fetchGrid(defaultCity);
        expect(
          requested.queryParameters['latitude']!.split(','),
          hasLength(25),
        );
        expect(requested.queryParameters['forecast_hours'], '8');
        expect(points, hasLength(25));
        expect(points[12].latitude, defaultCity.latitude); // centre
        expect(points[12].longitude, defaultCity.longitude);
        expect(points[0].latitude, closeTo(defaultCity.latitude - 1, 1e-9));
        final hour = points.first.hours.first;
        expect(hour.temperature, 20);
        expect(hour.windSpeed, 12.4);
        expect(hour.windDirection, 90);
        expect(hour.cloudCover, 40);
        expect(points.first.hours.last.windSpeed, 0); // valeur manquante
      },
    );

    test('erreur serveur : ApiException', () {
      final repository = OpenMeteoWeatherGridRepository(
        MockClient((_) async => http.Response('', 500)),
      );
      expect(repository.fetchGrid(defaultCity), throwsA(isA<ApiException>()));
    });
  });

  test('radar RainViewer indisponible : ApiException', () {
    final repository = RainViewerRadarRepository(
      MockClient((_) async => http.Response('', 500)),
    );
    expect(repository.fetchFrames(), throwsA(isA<ApiException>()));
  });
}
