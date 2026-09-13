import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meteo/features/alerts/application/alerts_controller.dart';
import 'package:meteo/features/alerts/data/alerts_repository.dart';
import 'package:meteo/features/alerts/domain/weather_alert.dart';

class _FakeAlertsRepository implements AlertsRepository {
  @override
  Future<List<WeatherAlert>> fetchAlerts() async {
    final now = DateTime(2026, 9, 12, 10);
    return [
      WeatherAlert(
        id: 'info',
        title: 'Info',
        summary: 'Résumé',
        zone: 'Zone',
        source: 'Source',
        severity: AlertSeverity.information,
        startsAt: now,
        endsAt: now.add(const Duration(hours: 1)),
        originalText: 'Texte',
      ),
      WeatherAlert(
        id: 'danger',
        title: 'Danger',
        summary: 'Résumé',
        zone: 'Zone',
        source: 'Source',
        severity: AlertSeverity.danger,
        startsAt: now,
        endsAt: now.add(const Duration(hours: 1)),
        originalText: 'Texte',
      ),
    ];
  }
}

class _FakeAlertNotificationService implements AlertNotificationService {
  bool enabled = false;

  @override
  bool get isEnabled => enabled;

  @override
  Future<void> configure() async => enabled = true;

  @override
  Future<void> disable() async => enabled = false;
}

void main() {
  test('trie les alertes par gravité', () async {
    final container = ProviderContainer(
      overrides: [
        alertsRepositoryProvider.overrideWithValue(_FakeAlertsRepository()),
      ],
    );
    addTearDown(container.dispose);

    final alerts = await container.read(alertsControllerProvider.future);

    expect(alerts.map((alert) => alert.id), ['danger', 'info']);
  });

  test('active et désactive les notifications explicitement', () async {
    final service = _FakeAlertNotificationService();
    final container = ProviderContainer(
      overrides: [
        alertNotificationServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(
      alertNotificationsEnabledProvider.notifier,
    );
    expect(container.read(alertNotificationsEnabledProvider), isFalse);

    await notifier.enable();
    expect(container.read(alertNotificationsEnabledProvider), isTrue);
    expect(service.enabled, isTrue);

    await notifier.disable();
    expect(container.read(alertNotificationsEnabledProvider), isFalse);
    expect(service.enabled, isFalse);
  });
}
