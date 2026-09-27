import 'dart:math' as math;

import '../../forecast/domain/daily_forecast.dart';
import '../../forecast/domain/hourly_forecast.dart';
import '../domain/forecast_bundle.dart';
import '../domain/weather_condition.dart';
import '../domain/weather_snapshot.dart';

/// Paramètres demandés à l'API Open-Meteo « forecast ».
abstract final class OpenMeteoFields {
  static const current =
      'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,'
      'is_day,wind_speed_10m,wind_direction_10m,wind_gusts_10m,pressure_msl,'
      'uv_index,visibility,dew_point_2m';
  static const hourly =
      'temperature_2m,weather_code,is_day,precipitation_probability,'
      'precipitation,wind_speed_10m,wind_direction_10m,wind_gusts_10m,'
      'relative_humidity_2m,cape';
  static const daily =
      'weather_code,temperature_2m_max,temperature_2m_min,'
      'precipitation_probability_max,precipitation_sum,snowfall_sum,'
      'wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant,'
      'uv_index_max,sunrise,sunset';
}

/// Transforme la réponse JSON Open-Meteo en [ForecastBundle].
///
/// Les heures renvoyées (`timezone=auto`) sont l'heure locale de la ville,
/// conservées telles quelles pour l'affichage.
ForecastBundle parseOpenMeteoForecast(
  Map<String, dynamic> json, {
  required String city,
  required DateTime fetchedAt,
  bool isOffline = false,
}) {
  final current = json['current'] as Map<String, dynamic>;
  final observedAt = DateTime.parse(current['time'] as String);

  final snapshot = WeatherSnapshot(
    city: city,
    temperature: _d(current['temperature_2m']),
    apparentTemperature: _d(
      current['apparent_temperature'] ?? current['temperature_2m'],
    ),
    condition: conditionFromWmo(_i(current['weather_code'])),
    isDay: _i(current['is_day'], 1) == 1,
    windSpeed: _d(current['wind_speed_10m']),
    windGust: _d(current['wind_gusts_10m']),
    windDirectionDegrees: _i(current['wind_direction_10m']),
    humidity: _d(current['relative_humidity_2m']),
    pressure: _d(current['pressure_msl']),
    uvIndex: _d(current['uv_index']),
    visibility: _d(current['visibility']),
    dewPoint: _d(current['dew_point_2m']),
    elevation: _d(json['elevation']),
    observedAt: observedAt,
    updatedAt: fetchedAt,
    isOffline: isOffline,
  );

  final hourlyJson = json['hourly'] as Map<String, dynamic>;
  final allHours = _parseHourly(hourlyJson);
  final currentHour = DateTime(
    observedAt.year,
    observedAt.month,
    observedAt.day,
    observedAt.hour,
  );
  final start = allHours.indexWhere((h) => !h.time.isBefore(currentHour));
  final upcoming = start < 0
      ? const <HourlyForecast>[]
      : allHours.sublist(start, math.min(start + 48, allHours.length));

  final daily = _parseDaily(
    json['daily'] as Map<String, dynamic>,
    allHours,
    _list(hourlyJson, 'cape'),
  );

  return ForecastBundle(current: snapshot, hourly: upcoming, daily: daily);
}

List<HourlyForecast> _parseHourly(Map<String, dynamic> hourly) {
  final times = _list(hourly, 'time');
  return List.generate(times.length, (i) {
    return HourlyForecast(
      time: DateTime.parse(times[i] as String),
      temperature: _d(_list(hourly, 'temperature_2m')[i]),
      weatherCode: _i(_list(hourly, 'weather_code')[i]),
      isDay: _i(_list(hourly, 'is_day')[i], 1) == 1,
      precipitationProbability: _i(
        _list(hourly, 'precipitation_probability')[i],
      ),
      precipitation: _d(_list(hourly, 'precipitation')[i]),
      windSpeed: _d(_list(hourly, 'wind_speed_10m')[i]),
      windGust: _d(_list(hourly, 'wind_gusts_10m')[i]),
      windDirectionDegrees: _i(_list(hourly, 'wind_direction_10m')[i]),
      humidity: _i(_list(hourly, 'relative_humidity_2m')[i]),
    );
  });
}

List<DailyForecast> _parseDaily(
  Map<String, dynamic> daily,
  List<HourlyForecast> hours,
  List<dynamic> cape,
) {
  final dates = _list(daily, 'time');
  return List.generate(dates.length, (i) {
    final date = DateTime.parse(dates[i] as String);
    final code = _i(_list(daily, 'weather_code')[i]);
    final pop = _i(_list(daily, 'precipitation_probability_max')[i]);
    final min = _d(_list(daily, 'temperature_2m_min')[i]);
    final precipitationSum = _d(_list(daily, 'precipitation_sum')[i]);
    final snowfall = _d(_list(daily, 'snowfall_sum')[i]);

    var humiditySum = 0;
    var humidityCount = 0;
    var maxCape = 0.0;
    for (var h = 0; h < hours.length; h++) {
      final hour = hours[h];
      if (!_sameDay(hour.time, date)) continue;
      humiditySum += hour.humidity;
      humidityCount++;
      if (h < cape.length) maxCape = math.max(maxCape, _d(cape[h]));
    }

    final condition = conditionFromWmo(code);
    return DailyForecast(
      date: date,
      minimumTemperature: min,
      maximumTemperature: _d(_list(daily, 'temperature_2m_max')[i]),
      weatherCode: code,
      rainProbability: pop,
      precipitationSum: precipitationSum,
      snowProbability: snowProbability(
        pop: pop,
        snowfall: snowfall,
        condition: condition,
      ),
      iceProbability: iceProbability(
        pop: pop,
        minimumTemperature: min,
        precipitationSum: precipitationSum,
        condition: condition,
      ),
      lightningProbability: lightningProbability(
        pop: pop,
        maxCape: maxCape,
        condition: condition,
      ),
      windSpeed: _d(_list(daily, 'wind_speed_10m_max')[i]),
      windGust: _d(_list(daily, 'wind_gusts_10m_max')[i]),
      windDirectionDegrees: _i(_list(daily, 'wind_direction_10m_dominant')[i]),
      uvIndex: _d(_list(daily, 'uv_index_max')[i]),
      humidity: humidityCount == 0 ? 0 : (humiditySum / humidityCount).round(),
      sunrise: DateTime.parse(_list(daily, 'sunrise')[i] as String),
      sunset: DateTime.parse(_list(daily, 'sunset')[i] as String),
    );
  });
}

/// Neige : probabilité de précipitation si de la neige est prévue.
int snowProbability({
  required int pop,
  required double snowfall,
  required WeatherCondition condition,
}) {
  if (condition == WeatherCondition.snow) return math.max(pop, 50);
  return snowfall > 0 ? pop : 0;
}

/// Verglas : pluie verglaçante prévue, ou précipitations avec gel nocturne.
int iceProbability({
  required int pop,
  required double minimumTemperature,
  required double precipitationSum,
  required WeatherCondition condition,
}) {
  if (condition == WeatherCondition.freezingRain) return math.max(pop, 50);
  if (minimumTemperature <= 1 && precipitationSum > 0) return pop ~/ 2;
  return 0;
}

/// Foudre : estimation à partir de l'énergie convective (CAPE) et du code
/// orage WMO. 2 500 J/kg de CAPE avec pluie certaine ≈ 100 %.
int lightningProbability({
  required int pop,
  required double maxCape,
  required WeatherCondition condition,
}) {
  final base = condition == WeatherCondition.thunderstorm
      ? math.max(50, pop)
      : 0;
  final convective = ((maxCape / 25).clamp(0, 100) * pop / 100).round();
  return math.max(base, convective).clamp(0, 100);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<dynamic> _list(Map<String, dynamic> json, String key) =>
    json[key] as List<dynamic>? ?? const [];

double _d(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : fallback;

int _i(Object? value, [int fallback = 0]) =>
    value is num ? value.round() : fallback;
