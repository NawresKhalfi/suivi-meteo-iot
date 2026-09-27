import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/storage/local_preferences.dart';
import '../domain/weather_alert.dart';

/// Historique des alertes par ville (E02 – US09).
abstract interface class AlertsHistoryStore {
  List<WeatherAlert> read(String cityId);
  Future<void> save(String cityId, List<WeatherAlert> alerts);
}

class SharedPreferencesAlertsHistoryStore implements AlertsHistoryStore {
  SharedPreferencesAlertsHistoryStore(this._preferences);

  final LocalPreferences _preferences;

  @override
  List<WeatherAlert> read(String cityId) {
    final value = _preferences.alertsHistory(cityId);
    if (value == null) return const [];
    try {
      return (jsonDecode(value) as List<dynamic>)
          .map((item) => WeatherAlert.fromJson(item as Map<String, dynamic>))
          .toList();
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> save(String cityId, List<WeatherAlert> alerts) =>
      _preferences.saveAlertsHistory(
        cityId,
        jsonEncode(alerts.map((a) => a.toJson()).toList()),
      );
}

class MemoryAlertsHistoryStore implements AlertsHistoryStore {
  final Map<String, List<WeatherAlert>> values = {};

  @override
  List<WeatherAlert> read(String cityId) => values[cityId] ?? const [];

  @override
  Future<void> save(String cityId, List<WeatherAlert> alerts) async =>
      values[cityId] = List.of(alerts);
}

/// Abonnement aux notifications push d'alertes (E02 – US06).
abstract interface class AlertNotificationService {
  bool get isEnabled;
  Future<void> configure();
  Future<void> disable();
}

class UnconfiguredAlertNotificationService implements AlertNotificationService {
  bool _enabled = false;

  @override
  bool get isEnabled => _enabled;

  @override
  Future<void> configure() async => _enabled = true;

  @override
  Future<void> disable() async => _enabled = false;
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
  Future<void> configure() => _preferences.saveAlertNotificationsEnabled(true);

  @override
  Future<void> disable() => _preferences.saveAlertNotificationsEnabled(false);
}
