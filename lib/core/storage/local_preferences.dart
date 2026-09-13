import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferences {
  LocalPreferences(this._preferences);

  final SharedPreferences _preferences;

  DateTime? get lastWeatherUpdate {
    final value = _preferences.getString('weather.last_update');
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> saveLastWeatherUpdate(DateTime value) {
    return _preferences.setString(
      'weather.last_update',
      value.toIso8601String(),
    );
  }

  String? get weatherSnapshot {
    return _preferences.getString('weather.snapshot');
  }

  Future<void> saveWeatherSnapshot(String value) {
    return _preferences.setString('weather.snapshot', value);
  }

  String? get savedCities => _preferences.getString('cities.saved');

  Future<void> saveCities(String value) {
    return _preferences.setString('cities.saved', value);
  }

  String? get selectedCity => _preferences.getString('cities.selected');

  Future<void> saveSelectedCity(String value) {
    return _preferences.setString('cities.selected', value);
  }

  bool get alertNotificationsEnabled =>
      _preferences.getBool('alerts.notifications_enabled') ?? false;

  Future<void> saveAlertNotificationsEnabled(bool value) {
    return _preferences.setBool('alerts.notifications_enabled', value);
  }
}
