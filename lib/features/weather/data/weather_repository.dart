import 'dart:convert';

import '../../../core/storage/local_preferences.dart';
import '../domain/weather_snapshot.dart';

abstract interface class WeatherRepository {
  Future<WeatherSnapshot> fetchCurrentWeather();
}

abstract interface class WeatherLocalStore {
  Future<void> save(WeatherSnapshot snapshot);
  WeatherSnapshot? read();
}

class SharedPreferencesWeatherLocalStore implements WeatherLocalStore {
  SharedPreferencesWeatherLocalStore(this._preferences);

  final LocalPreferences _preferences;

  @override
  WeatherSnapshot? read() {
    final value = _preferences.weatherSnapshot;
    if (value == null) return null;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return WeatherSnapshot(
        city: json['city'] as String,
        temperature: (json['temperature'] as num).toDouble(),
        condition: WeatherCondition.values.byName(json['condition'] as String),
        windSpeed: (json['windSpeed'] as num).toDouble(),
        windDirection: json['windDirection'] as String,
        humidity: (json['humidity'] as num).toDouble(),
        pressure: (json['pressure'] as num).toDouble(),
        uvIndex: (json['uvIndex'] as num).toDouble(),
        visibility: (json['visibility'] as num).toDouble(),
        dewPoint: (json['dewPoint'] as num).toDouble(),
        elevation: (json['elevation'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        isOffline: true,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(WeatherSnapshot snapshot) {
    return _preferences.saveWeatherSnapshot(
      jsonEncode({
        'city': snapshot.city,
        'temperature': snapshot.temperature,
        'condition': snapshot.condition.name,
        'windSpeed': snapshot.windSpeed,
        'windDirection': snapshot.windDirection,
        'humidity': snapshot.humidity,
        'pressure': snapshot.pressure,
        'uvIndex': snapshot.uvIndex,
        'visibility': snapshot.visibility,
        'dewPoint': snapshot.dewPoint,
        'elevation': snapshot.elevation,
        'updatedAt': snapshot.updatedAt.toIso8601String(),
      }),
    );
  }
}

class MemoryWeatherLocalStore implements WeatherLocalStore {
  WeatherSnapshot? _snapshot;

  @override
  WeatherSnapshot? read() => _snapshot;

  @override
  Future<void> save(WeatherSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}

class DemoWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherSnapshot> fetchCurrentWeather() async {
    return WeatherSnapshot(
      city: 'Paris',
      temperature: 21.8,
      condition: WeatherCondition.sunny,
      windSpeed: 13.7,
      windDirection: 'SO',
      humidity: 66.5,
      pressure: 1012.8,
      uvIndex: 5,
      visibility: 10,
      dewPoint: 14.9,
      elevation: 35,
      updatedAt: DateTime.now(),
    );
  }
}
