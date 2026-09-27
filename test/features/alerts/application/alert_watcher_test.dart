import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/alerts/application/alert_watcher.dart';
import 'package:meteo/features/alerts/domain/alert_rules.dart';
import 'package:meteo/features/alerts/domain/weather_alert.dart';

WeatherAlert alert(String id, AlertSeverity severity, {DateTime? endsAt}) =>
    WeatherAlert(
      id: id,
      title: id,
      summary: '…',
      zone: 'Nabeul et environs',
      source: alertSource,
      severity: severity,
      startsAt: DateTime(2026, 9, 27, 18),
      endsAt: endsAt ?? DateTime(2026, 9, 27, 21),
      originalText: '…',
    );

void main() {
  final now = DateTime(2026, 9, 27, 16);

  test(
    'notifie les nouvelles alertes importantes, la plus grave en premier',
    () {
      final result = alertsToNotify(
        [
          alert('wind-1', AlertSeverity.vigilance),
          alert('fire-1', AlertSeverity.danger),
          alert('shower-1', AlertSeverity.information),
          alert('uv-1', AlertSeverity.information),
        ],
        now: now,
        alreadyNotified: const {},
      );
      expect(result.map((a) => a.id), ['fire-1', 'wind-1', 'shower-1']);
    },
  );

  test('ignore les alertes déjà notifiées ou terminées', () {
    final result = alertsToNotify(
      [
        alert('storm-1', AlertSeverity.danger),
        alert(
          'wind-old',
          AlertSeverity.danger,
          endsAt: DateTime(2026, 9, 27, 10),
        ),
      ],
      now: now,
      alreadyNotified: const {'storm-1'},
    );
    expect(result, isEmpty);
  });
}
