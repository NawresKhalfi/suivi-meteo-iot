import '../domain/weather_alert.dart';
import '../../../core/storage/local_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

abstract interface class AlertsRepository {
  Future<List<WeatherAlert>> fetchAlerts();
}

abstract interface class AlertNotificationService {
  bool get isEnabled;

  Future<void> configure();

  Future<void> disable();
}

class UnconfiguredAlertNotificationService implements AlertNotificationService {
  @override
  bool get isEnabled => false;

  @override
  Future<void> configure() async {}

  @override
  Future<void> disable() async {}
}

class FirebaseAlertNotificationService implements AlertNotificationService {
  FirebaseAlertNotificationService(this._preferences);

  final LocalPreferences _preferences;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  bool get isEnabled => _preferences.alertNotificationsEnabled;

  @override
  Future<void> configure() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      throw StateError('Les notifications ont été refusées.');
    }
    await _messaging.subscribeToTopic('weather-alerts');
    await _preferences.saveAlertNotificationsEnabled(true);
  }

  @override
  Future<void> disable() async {
    await _messaging.unsubscribeFromTopic('weather-alerts');
    await _preferences.saveAlertNotificationsEnabled(false);
  }
}

class SharedPreferencesAlertNotificationService
    implements AlertNotificationService {
  SharedPreferencesAlertNotificationService(this._preferences);

  final LocalPreferences _preferences;

  @override
  bool get isEnabled => _preferences.alertNotificationsEnabled;

  @override
  Future<void> configure() {
    return _preferences.saveAlertNotificationsEnabled(true);
  }

  @override
  Future<void> disable() {
    return _preferences.saveAlertNotificationsEnabled(false);
  }
}

class DemoAlertsRepository implements AlertsRepository {
  @override
  Future<List<WeatherAlert>> fetchAlerts() async {
    final now = DateTime.now();
    return [
      WeatherAlert(
        id: 'storm-1',
        title: 'Orages localisés',
        summary: 'Risque d\'orages et de fortes rafales en soirée.',
        zone: 'Paris et petite couronne',
        source: 'Météo France',
        severity: AlertSeverity.danger,
        startsAt: now.subtract(const Duration(hours: 1)),
        endsAt: now.add(const Duration(hours: 5)),
        originalText:
            'Des orages localement forts peuvent provoquer de fortes rafales et des ruissellements rapides.',
      ),
      WeatherAlert(
        id: 'heat-1',
        title: 'Vigilance chaleur',
        summary: 'Températures élevées attendues cet après-midi.',
        zone: 'Île-de-France',
        source: 'Météo France',
        severity: AlertSeverity.vigilance,
        startsAt: now.subtract(const Duration(hours: 3)),
        endsAt: now.add(const Duration(hours: 10)),
        originalText:
            'Hydratez-vous régulièrement et limitez les efforts physiques aux heures les plus chaudes.',
      ),
      WeatherAlert(
        id: 'wind-old',
        title: 'Vent fort hier',
        summary: 'Épisode de vent désormais terminé.',
        zone: 'Paris',
        source: 'Météo France',
        severity: AlertSeverity.information,
        startsAt: now.subtract(const Duration(hours: 30)),
        endsAt: now.subtract(const Duration(hours: 26)),
        originalText:
            'Épisode terminé. Consultez les prévisions locales pour les prochaines heures.',
      ),
    ];
  }
}
