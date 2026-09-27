import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/alerts/application/alerts_controller.dart';
import 'package:meteo/features/alerts/data/alerts_repository.dart';
import 'package:meteo/features/alerts/domain/alert_rules.dart';
import 'package:meteo/features/alerts/domain/weather_alert.dart';
import 'package:meteo/features/cities/domain/city.dart';
import 'package:meteo/features/settings/domain/unit_formatter.dart';
import 'package:meteo/features/settings/domain/unit_settings.dart';
import 'package:meteo/features/weather/application/weather_controller.dart';
import 'package:meteo/features/weather/data/open_meteo_parser.dart';
import 'package:meteo/features/weather/domain/forecast_bundle.dart';

import '../../../helpers/fakes.dart';

const format = UnitFormatter(UnitSettings());

/// Fixture réelle modifiée : orage avec fortes rafales de 18h à 20h.
ForecastBundle stormyBundle() {
  final json = loadForecastJson();
  final hourly = json['hourly'] as Map<String, dynamic>;
  final times = hourly['time'] as List;
  final start = times.indexOf('2026-09-27T18:00');
  for (var i = start; i < start + 3; i++) {
    (hourly['weather_code'] as List)[i] = 95;
    (hourly['wind_gusts_10m'] as List)[i] = 75.0;
    (hourly['precipitation'] as List)[i] = 9.0;
  }
  return parseOpenMeteoForecast(
    json,
    city: 'Nabeul',
    fetchedAt: DateTime.now(),
  );
}

void main() {
  test('aucune alerte par temps calme (fixture réelle)', () {
    expect(deriveAlerts(loadBundle(), zone: 'Nabeul', format: format), isEmpty);
  });

  test('détecte orage, vent fort et fortes pluies, triés par gravité', () {
    final alerts = deriveAlerts(stormyBundle(), zone: 'Nabeul', format: format);
    final titles = alerts.map((a) => a.title).toList();
    expect(
      titles,
      containsAll(['Alerte orages violents', 'Vent fort', 'Fortes pluies']),
    );
    expect(alerts.first.severity, AlertSeverity.danger);
    final storm = alerts.first;
    expect(storm.startsAt, DateTime(2026, 9, 27, 18));
    expect(storm.endsAt, DateTime(2026, 9, 27, 21));
    expect(storm.zone, 'Nabeul et environs');
    expect(storm.summary, contains('75 km/h'));
  });

  test(
    'le contrôleur sépare en cours / à venir et garde l’historique',
    () async {
      final history = MemoryAlertsHistoryStore();
      final old = WeatherAlert(
        id: 'wind-old',
        title: 'Vent fort',
        summary: '…',
        zone: 'Nabeul et environs',
        source: alertSource,
        severity: AlertSeverity.vigilance,
        startsAt: DateTime(2026, 9, 26, 10),
        endsAt: DateTime(2026, 9, 26, 14),
        originalText: '…',
      );
      final tooOld = WeatherAlert.fromJson({
        ...old.toJson(),
        'id': 'too-old',
        'endsAt': DateTime(2026, 9, 24).toIso8601String(),
      });
      await history.save(defaultCity.id, [old, tooOld]);

      final container = ProviderContainer(
        overrides: [
          ...testOverrides(),
          weatherRepositoryProvider.overrideWithValue(_StormyRepository()),
          alertsHistoryStoreProvider.overrideWithValue(history),
        ],
      );
      addTearDown(container.dispose);
      await container.read(weatherControllerProvider.future);

      final state = container.read(alertsControllerProvider);
      expect(state.active, isEmpty); // il est 16:15, l'orage commence à 18h
      expect(state.upcoming.first.title, 'Alerte orages violents');
      expect(state.history.map((a) => a.id), ['wind-old']);
      expect(state.hasAlerts, isTrue);
    },
  );
}

class _StormyRepository extends FakeWeatherRepository {
  @override
  Future<ForecastBundle> fetchForecast(City city) async => stormyBundle();
}
