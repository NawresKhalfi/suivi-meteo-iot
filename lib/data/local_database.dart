import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Measurement {
  final int? id;
  final String type; // temperature, humidity, wind, pressure
  final double value;
  final DateTime timestamp;

  Measurement({
    this.id,
    required this.type,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static Measurement fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as int?,
      type: map['type'] as String,
      value: (map['value'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class AlertItem {
  final String label;
  final String message;
  final String type;

  AlertItem({
    required this.label,
    required this.message,
    required this.type,
  });
}

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  Database? _db;

  // Stockage en mémoire pour la plateforme Web
  final Map<String, double> _memoryThresholds = {};
  final List<Measurement> _memoryMeasurements = [];

  Future<Database> get database async {
    if (kIsWeb) {
      // Ne pas utiliser sqflite sur le Web.
      throw UnsupportedError('SQLite database is not available on the Web.');
    }
    if (_db != null) return _db!;
    _db = await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    // Cette méthode n'est jamais appelée sur le Web (voir getter ci‑dessus).
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'suivi_meteo_iot.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE thresholds (
            key TEXT PRIMARY KEY,
            value REAL NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE measurements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            value REAL NOT NULL,
            timestamp TEXT NOT NULL
          );
        ''');
      },
    );
  }

  Future<void> init() async {
    if (kIsWeb) {
      // Version Web : initialise des données en mémoire.
      if (_memoryThresholds.isEmpty) {
        _memoryThresholds['temperature_max'] = 25;
        _memoryThresholds['humidity_max'] = 80;
        _memoryThresholds['wind_max'] = 40;
        _memoryThresholds['pressure_min'] = 980;
      }
      if (_memoryMeasurements.isEmpty) {
        final now = DateTime.now();
        _memoryMeasurements.addAll([
          Measurement(type: 'temperature', value: 28.5, timestamp: now),
          Measurement(type: 'humidity', value: 70, timestamp: now),
          Measurement(type: 'wind', value: 10, timestamp: now),
          Measurement(type: 'pressure', value: 990, timestamp: now),
        ]);
      }
      return;
    }

    final db = await database;

    final existingThresholds =
        await db.query('thresholds', columns: ['key'], limit: 1);
    if (existingThresholds.isEmpty) {
      await db.insert('thresholds', {'key': 'temperature_max', 'value': 25});
      await db.insert('thresholds', {'key': 'humidity_max', 'value': 80});
      await db.insert('thresholds', {'key': 'wind_max', 'value': 40});
      await db.insert('thresholds', {'key': 'pressure_min', 'value': 980});
    }

    final existingMeasurements =
        await db.query('measurements', columns: ['id'], limit: 1);
    if (existingMeasurements.isEmpty) {
      final now = DateTime.now();
      await db.insert(
        'measurements',
        Measurement(
          type: 'temperature',
          value: 28.5,
          timestamp: now,
        ).toMap(),
      );
      await db.insert(
        'measurements',
        Measurement(
          type: 'humidity',
          value: 70,
          timestamp: now,
        ).toMap(),
      );
      await db.insert(
        'measurements',
        Measurement(
          type: 'wind',
          value: 10,
          timestamp: now,
        ).toMap(),
      );
      await db.insert(
        'measurements',
        Measurement(
          type: 'pressure',
          value: 990,
          timestamp: now,
        ).toMap(),
      );
    }
  }

  Future<Map<String, double>> getThresholds() async {
    if (kIsWeb) {
      if (_memoryThresholds.isEmpty) {
        await init();
      }
      return Map<String, double>.from(_memoryThresholds);
    }

    final db = await database;
    final rows = await db.query('thresholds');

    final result = <String, double>{};
    for (final row in rows) {
      result[row['key'] as String] = (row['value'] as num).toDouble();
    }
    return result;
  }

  Future<void> updateThreshold(String key, double value) async {
    if (kIsWeb) {
      _memoryThresholds[key] = value;
      return;
    }

    final db = await database;
    await db.insert(
      'thresholds',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMeasurement(Measurement measurement) async {
    if (kIsWeb) {
      _memoryMeasurements.add(measurement);
      return;
    }

    final db = await database;
    await db.insert('measurements', measurement.toMap());
  }

  Future<Measurement?> getLatestMeasurement(String type) async {
    if (kIsWeb) {
      for (var i = _memoryMeasurements.length - 1; i >= 0; i--) {
        if (_memoryMeasurements[i].type == type) {
          return _memoryMeasurements[i];
        }
      }
      return null;
    }

    final db = await database;
    final rows = await db.query(
      'measurements',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Measurement.fromMap(rows.first);
  }

  Future<List<AlertItem>> getActiveAlerts() async {
    final thresholds = await getThresholds();

    final temperature = await getLatestMeasurement('temperature');
    final humidity = await getLatestMeasurement('humidity');
    final wind = await getLatestMeasurement('wind');
    final pressure = await getLatestMeasurement('pressure');

    final alerts = <AlertItem>[];

    if (temperature != null &&
        temperature.value >
            (thresholds['temperature_max'] ?? double.infinity)) {
      alerts.add(
        AlertItem(
          label: 'Température',
          type: 'temperature',
          message:
              'Température élevée détectée: ${temperature.value.toStringAsFixed(1)}°C '
              '(seuil: ${(thresholds['temperature_max'] ?? 0).toStringAsFixed(1)}°C)',
        ),
      );
    }

    if (humidity != null &&
        humidity.value > (thresholds['humidity_max'] ?? double.infinity)) {
      alerts.add(
        AlertItem(
          label: 'Humidité',
          type: 'humidity',
          message:
              'Humidité élevée détectée: ${humidity.value.toStringAsFixed(1)}% '
              '(seuil: ${(thresholds['humidity_max'] ?? 0).toStringAsFixed(0)}%)',
        ),
      );
    }

    if (wind != null &&
        wind.value > (thresholds['wind_max'] ?? double.infinity)) {
      alerts.add(
        AlertItem(
          label: 'Vent',
          type: 'wind',
          message:
              'Vitesse du vent élevée: ${wind.value.toStringAsFixed(1)} km/h '
              '(seuil: ${(thresholds['wind_max'] ?? 0).toStringAsFixed(1)} km/h)',
        ),
      );
    }

    if (pressure != null &&
        pressure.value < (thresholds['pressure_min'] ?? double.negativeInfinity)) {
      alerts.add(
        AlertItem(
          label: 'Pression',
          type: 'pressure',
          message:
              'Pression basse détectée: ${pressure.value.toStringAsFixed(0)} hPa '
              '(seuil: ${(thresholds['pressure_min'] ?? 0).toStringAsFixed(0)} hPa)',
        ),
      );
    }

    return alerts;
  }
}
