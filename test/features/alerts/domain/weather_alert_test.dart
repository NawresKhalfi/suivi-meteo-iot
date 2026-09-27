import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/core/storage/local_preferences.dart';
import 'package:meteo/features/alerts/application/alerts_controller.dart';
import 'package:meteo/features/alerts/data/alerts_repository.dart';
import 'package:meteo/features/alerts/domain/alert_rules.dart';
import 'package:meteo/features/alerts/domain/weather_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

WeatherAlert alert(
  String id,
  AlertSeverity severity, {
  int startHour = 18,
  int endHour = 21,
}) => WeatherAlert(
  id: id,
  title: id,
  summary: 'Résumé',
  zone: 'Nabeul et environs',
  source: alertSource,
  severity: severity,
  startsAt: DateTime(2026, 9, 27, startHour),
  endsAt: DateTime(2026, 9, 27, endHour),
  originalText: 'Rafales ≥ 60 km/h',
);

void main() {
  group('WeatherAlert', () {
    test('en cours entre le début (inclus) et la fin (exclue)', () {
      final a = alert('a', AlertSeverity.vigilance);
      expect(a.isActiveAt(DateTime(2026, 9, 27, 17, 59)), isFalse);
      expect(a.isUpcomingAt(DateTime(2026, 9, 27, 17, 59)), isTrue);
      expect(a.isActiveAt(DateTime(2026, 9, 27, 18)), isTrue);
      expect(a.isUpcomingAt(DateTime(2026, 9, 27, 18)), isFalse);
      expect(a.isActiveAt(DateTime(2026, 9, 27, 21)), isFalse);
    });

    test('US08 : tri par gravité décroissante puis par début', () {
      final alerts = [
        alert('info', AlertSeverity.information, startHour: 10),
        alert('danger-late', AlertSeverity.danger, startHour: 20),
        alert('extreme', AlertSeverity.extreme),
        alert('danger-early', AlertSeverity.danger, startHour: 12),
      ]..sort(compareAlerts);
      expect(alerts.map((a) => a.id), [
        'extreme',
        'danger-early',
        'danger-late',
        'info',
      ]);
    });

    test('sérialisation JSON aller-retour (historique US09)', () {
      final original = alert('storm-1', AlertSeverity.danger);
      final copy = WeatherAlert.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.severity, AlertSeverity.danger);
      expect(copy.startsAt, original.startsAt);
      expect(copy.endsAt, original.endsAt);
      expect(copy.originalText, original.originalText);
    });

    test('libellés de gravité', () {
      expect(AlertSeverity.information.label, 'Information');
      expect(AlertSeverity.vigilance.label, 'Vigilance jaune');
      expect(AlertSeverity.danger.label, 'Danger — Vigilance orange');
      expect(AlertSeverity.extreme.label, 'Extrême — Vigilance rouge');
    });
  });

  group('AlertsState', () {
    test("l'alerte la plus grave privilégie celles en cours", () {
      final active = alert('active', AlertSeverity.information);
      final upcoming = alert('upcoming', AlertSeverity.extreme);
      expect(
        AlertsState(active: [active], upcoming: [upcoming]).mostSevere,
        active,
      );
      expect(AlertsState(upcoming: [upcoming]).mostSevere, upcoming);
      expect(const AlertsState().mostSevere, isNull);
      expect(const AlertsState().hasAlerts, isFalse);
    });
  });

  group('SharedPreferencesAlertsHistoryStore', () {
    test('persiste l’historique par ville', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesAlertsHistoryStore(
        LocalPreferences(await SharedPreferences.getInstance()),
      );
      await store.save('nabeul', [alert('storm-1', AlertSeverity.danger)]);
      expect(store.read('nabeul').single.id, 'storm-1');
      expect(store.read('paris'), isEmpty);
    });

    test('un historique corrompu est ignoré', () async {
      SharedPreferences.setMockInitialValues({
        'alerts.history.nabeul': 'pas du json',
      });
      final store = SharedPreferencesAlertsHistoryStore(
        LocalPreferences(await SharedPreferences.getInstance()),
      );
      expect(store.read('nabeul'), isEmpty);
    });
  });

  test('US06 : activer puis désactiver les notifications d’alerte', () async {
    final service = UnconfiguredAlertNotificationService();
    final container = ProviderContainer(
      overrides: [alertNotificationServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(alertNotificationsEnabledProvider.notifier);

    expect(container.read(alertNotificationsEnabledProvider), isFalse);
    await notifier.enable();
    expect(container.read(alertNotificationsEnabledProvider), isTrue);
    expect(service.isEnabled, isTrue);
    await notifier.disable();
    expect(container.read(alertNotificationsEnabledProvider), isFalse);
    expect(service.isEnabled, isFalse);
  });
}
