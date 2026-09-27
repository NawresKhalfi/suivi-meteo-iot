import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/storage/local_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../cities/data/cities_store.dart';
import '../../cities/domain/city.dart';
import '../../settings/data/home_screen_widget.dart';
import '../../settings/data/settings_store.dart';
import '../../settings/domain/unit_formatter.dart';
import '../../weather/data/weather_cache_store.dart';
import '../../weather/data/weather_repository.dart';
import '../data/alerts_repository.dart';
import '../data/hazard_repository.dart';
import '../domain/alert_rules.dart';
import '../domain/hazard_event.dart';
import '../domain/weather_alert.dart';

/// Identifiant de la tâche périodique (doit correspondre à
/// `BGTaskSchedulerPermittedIdentifiers` dans ios/Runner/Info.plist).
const alertWatchTask = 'com.example.meteo.alertWatch';

/// Rafraîchissement en arrière-plan (alertes + widget) : Android
/// (WorkManager) et iOS (BGTaskScheduler) uniquement.
bool get alertWatchSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

@pragma('vm:entry-point')
void alertWatchDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await refreshInBackground();
      return true;
    } on Object catch (error) {
      debugPrint('Rafraîchissement en arrière-plan : $error');
      return false;
    }
  });
}

/// Alertes à notifier : nouvelles, pas encore terminées, et assez importantes
/// (vigilance ou plus, ou pluie prévue).
List<WeatherAlert> alertsToNotify(
  List<WeatherAlert> alerts, {
  required DateTime now,
  required Set<String> alreadyNotified,
}) =>
    alerts
        .where(
          (a) =>
              !alreadyNotified.contains(a.id) &&
              a.endsAt.isAfter(now) &&
              (a.severity.priority >= AlertSeverity.vigilance.priority ||
                  a.id.startsWith('shower-')),
        )
        .toList()
      ..sort(compareAlerts);

/// Pour la ville par défaut : met à jour le widget d'écran d'accueil s'il est
/// installé, puis notifie les nouvelles alertes si elles sont activées.
Future<void> refreshInBackground() async {
  final prefs = LocalPreferences(await SharedPreferences.getInstance());
  await prefs.reload();
  final notify = prefs.alertNotificationsEnabled;
  final widget = platformHomeScreenWidget();
  final hasWidget = await widget.isInstalled().catchError((Object _) => false);
  if (!notify && !hasWidget) return;

  final stored = SharedPreferencesCitiesStore(prefs).read();
  final city = stored.cities.firstWhere(
    (c) => c.id == stored.defaultCityId,
    orElse: () => stored.cities.isNotEmpty ? stored.cities.first : defaultCity,
  );
  final format = UnitFormatter(SharedPreferencesSettingsStore(prefs).read());

  final client = http.Client();
  try {
    final bundle = await OpenMeteoWeatherRepository(
      client,
      SharedPreferencesWeatherCacheStore(prefs),
    ).fetchForecast(city);
    if (hasWidget) {
      await widget.update(
        HomeScreenWidgetData.from(city, bundle.current, format),
      );
    }
    if (!notify) return;

    var hazards = const <HazardEvent>[];
    try {
      hazards = await GdacsHazardRepository(client).fetchCurrentEvents();
    } on Object {
      // GDACS indisponible : on notifie quand même les alertes météo.
    }
    final alerts = [
      ...deriveAlerts(bundle, zone: city.name, format: format),
      ...hazardAlerts(hazards, city: city, now: bundle.current.observedAt),
    ];

    final notified = prefs.notifiedAlertIds;
    final fresh = alertsToNotify(
      alerts,
      now: DateTime.now(),
      alreadyNotified: notified.toSet(),
    );
    if (fresh.isEmpty) return;

    await AlertNotifications.initialize();
    for (final alert in fresh) {
      await AlertNotifications.show(alert, city);
    }
    await prefs.saveNotifiedAlertIds(
      [...fresh.map((a) => a.id), ...notified].take(200).toList(),
    );
  } finally {
    client.close();
  }
}

/// Notifications locales des alertes météo.
abstract final class AlertNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static NotificationDetails _details(String text) => NotificationDetails(
    android: AndroidNotificationDetails(
      'weather_alerts',
      'Alertes météo',
      channelDescription:
          'Pluie, orages, vent, incendies et catastrophes près de votre ville',
      icon: 'ic_stat_alert',
      color: AppColors.primary1,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(text),
    ),
    iOS: const DarwinNotificationDetails(),
  );

  static Future<void> initialize() => _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_alert'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );

  /// Demande l'autorisation d'afficher des notifications.
  static Future<bool> requestPermission() async {
    await initialize();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          true;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  static Future<void> show(WeatherAlert alert, City city) {
    final icon = alert.severity.priority >= AlertSeverity.danger.priority
        ? '🚨'
        : alert.severity == AlertSeverity.vigilance
        ? '⚠️'
        : '🌧️';
    return _plugin.show(
      id: alert.id.hashCode & 0x7fffffff,
      title: '$icon ${alert.title} · ${city.name}',
      body: alert.summary,
      notificationDetails: _details(alert.summary),
    );
  }
}

/// Active les notifications locales des alertes (vérifiées en arrière-plan).
class LocalAlertNotificationService implements AlertNotificationService {
  LocalAlertNotificationService(this._preferences);

  final LocalPreferences _preferences;

  static const _frequency = Duration(minutes: 30);

  @override
  bool get isEnabled => _preferences.alertNotificationsEnabled;

  /// À appeler au démarrage. La tâche tourne toujours mais ne fait rien si
  /// ni les alertes ni le widget ne sont utilisés.
  static Future<void> start(LocalPreferences preferences) async {
    if (!alertWatchSupported) return;
    await Workmanager().initialize(alertWatchDispatcher);
    await Workmanager().registerPeriodicTask(
      alertWatchTask,
      alertWatchTask,
      frequency: _frequency,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  @override
  Future<void> configure() async {
    if (alertWatchSupported && !await AlertNotifications.requestPermission()) {
      throw StateError('Les notifications ont été refusées.');
    }
    await _preferences.saveAlertNotificationsEnabled(true);
    if (!alertWatchSupported) return;
    // Vérification immédiate, sans attendre la première exécution planifiée.
    await refreshInBackground().catchError((Object _) {});
  }

  @override
  Future<void> disable() => _preferences.saveAlertNotificationsEnabled(false);
}
