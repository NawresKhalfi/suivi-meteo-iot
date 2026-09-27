import 'dart:convert';

import '../../../core/storage/local_preferences.dart';
import '../domain/unit_settings.dart';

abstract interface class SettingsStore {
  UnitSettings read();
  Future<void> save(UnitSettings settings);
}

class SharedPreferencesSettingsStore implements SettingsStore {
  SharedPreferencesSettingsStore(this._preferences);

  final LocalPreferences _preferences;

  @override
  UnitSettings read() {
    final value = _preferences.unitSettings;
    if (value == null) return const UnitSettings();
    try {
      return UnitSettings.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } on Object {
      return const UnitSettings();
    }
  }

  @override
  Future<void> save(UnitSettings settings) =>
      _preferences.saveUnitSettings(jsonEncode(settings.toJson()));
}

class MemorySettingsStore implements SettingsStore {
  UnitSettings value = const UnitSettings();

  @override
  UnitSettings read() => value;

  @override
  Future<void> save(UnitSettings settings) async => value = settings;
}
