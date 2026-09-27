import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/alerts/application/alerts_controller.dart';
import 'package:meteo/features/alerts/data/hazard_repository.dart';
import 'package:meteo/features/alerts/domain/hazard_event.dart';
import 'package:meteo/features/alerts/domain/weather_alert.dart';
import 'package:meteo/features/cities/domain/city.dart';
import 'package:meteo/features/weather/application/weather_controller.dart';

import '../../../helpers/fakes.dart';

Map<String, dynamic> feature({
  required String type,
  required int id,
  required double lat,
  required double lon,
  String level = 'Green',
  String geometry = 'Point',
  String kind = 'Point_Centroid',
}) => {
  'type': 'Feature',
  'geometry': {
    'type': geometry,
    'coordinates': [lon, lat],
  },
  'properties': {
    'eventtype': type,
    'eventid': id,
    'name': 'Event $id',
    'country': 'Tunisia',
    'alertlevel': level,
    'fromdate': '2026-09-26T00:00:00',
    'todate': '2026-09-26T12:00:00',
    'htmldescription': '$level event $id',
    'Class': kind,
    'severitydata': {'severitytext': '1200 ha'},
  },
};

HazardEvent event(HazardType type, double lat, double lon, HazardLevel level) =>
    HazardEvent(
      id: '1',
      type: type,
      level: level,
      name: 'Forest fires in Tunisia',
      country: 'Tunisia',
      latitude: lat,
      longitude: lon,
      from: DateTime(2026, 9, 26),
      to: DateTime(2026, 9, 26, 12),
      description: 'Forest fires in Tunisia',
    );

void main() {
  test('parse les centroïdes GDACS et ignore le reste', () {
    final events = parseGdacsEvents({
      'features': [
        feature(type: 'WF', id: 1, lat: 36.6, lon: 10.8, level: 'Orange'),
        feature(type: 'WF', id: 1, lat: 36.6, lon: 10.8), // doublon
        feature(type: 'WF', id: 2, lat: 0, lon: 0, kind: 'Poly_area'),
        feature(type: 'XX', id: 3, lat: 0, lon: 0),
      ],
    });
    expect(events, hasLength(1));
    expect(events.single.type, HazardType.wildfire);
    expect(events.single.level, HazardLevel.orange);
    expect(events.single.latitude, 36.6);
    expect(events.single.from, DateTime.utc(2026, 9, 26).toLocal());
    expect(events.single.severityText, '1200 ha');
  });

  test('distance de haversine', () {
    // Nabeul → Tunis ≈ 60 km.
    expect(distanceKm(36.456, 10.735, 36.806, 10.181), closeTo(63, 3));
  });

  test('seuls les événements proches de la ville deviennent des alertes', () {
    final now = DateTime(2026, 9, 27, 16);
    final alerts = hazardAlerts(
      [
        event(HazardType.wildfire, 36.6, 10.8, HazardLevel.orange), // ~17 km
        event(HazardType.wildfire, 12, 20, HazardLevel.red), // Tchad
      ],
      city: defaultCity,
      now: now,
    );
    expect(alerts, hasLength(1));
    final fire = alerts.single;
    expect(fire.title, 'Incendie de forêt à proximité');
    expect(fire.severity, AlertSeverity.danger);
    expect(fire.source, hazardSource);
    expect(fire.isActiveAt(now), isTrue);
    expect(fire.summary, contains('km de ${defaultCity.name}'));
  });

  test('le contrôleur ajoute les alertes GDACS aux alertes météo', () async {
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        hazardRepositoryProvider.overrideWithValue(
          FakeHazardRepository([
            event(HazardType.flood, 36.5, 10.7, HazardLevel.green),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(weatherControllerProvider.future);
    await container.read(hazardEventsProvider.future);

    final state = container.read(alertsControllerProvider);
    expect(state.active.map((a) => a.title), ['Inondation en cours']);
  });
}
