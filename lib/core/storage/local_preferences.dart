import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper typé autour de SharedPreferences. Chaque feature passe par ses
/// propres « stores » (couche `data/`) qui s'appuient sur ces accesseurs.
class LocalPreferences {
  LocalPreferences(this._preferences);

  final SharedPreferences _preferences;

  String? weatherCache(String cityId) =>
      _preferences.getString('weather.cache.$cityId');

  Future<void> saveWeatherCache(String cityId, String value) =>
      _preferences.setString('weather.cache.$cityId', value);

  String? get savedCities => _preferences.getString('cities.v2');

  Future<void> saveCities(String value) =>
      _preferences.setString('cities.v2', value);

  String? get unitSettings => _preferences.getString('settings.units');

  Future<void> saveUnitSettings(String value) =>
      _preferences.setString('settings.units', value);

  String? alertsHistory(String cityId) =>
      _preferences.getString('alerts.history.$cityId');

  Future<void> saveAlertsHistory(String cityId, String value) =>
      _preferences.setString('alerts.history.$cityId', value);

  bool get alertNotificationsEnabled =>
      _preferences.getBool('alerts.notifications_enabled') ?? false;

  Future<void> saveAlertNotificationsEnabled(bool value) =>
      _preferences.setBool('alerts.notifications_enabled', value);

  /// Identifiants des alertes déjà envoyées en notification.
  List<String> get notifiedAlertIds =>
      _preferences.getStringList('alerts.notified') ?? const [];

  Future<void> saveNotifiedAlertIds(List<String> ids) =>
      _preferences.setStringList('alerts.notified', ids);

  /// Relit le disque : la tâche d'arrière-plan tourne dans un autre isolate.
  Future<void> reload() => _preferences.reload();
}
