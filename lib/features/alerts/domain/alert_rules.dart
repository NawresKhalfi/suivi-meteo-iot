import 'dart:math' as math;

import '../../settings/domain/unit_formatter.dart';
import '../../weather/domain/forecast_bundle.dart';
import '../../weather/domain/weather_condition.dart';
import '../../forecast/domain/hourly_forecast.dart';
import 'weather_alert.dart';

const alertSource = 'Analyse des prévisions Open-Meteo';

/// Déduit les alertes météo des prochaines 48 h à partir des prévisions.
///
/// Seuils inspirés des critères de vigilance usuels (Météo-France / INM) :
/// orages, rafales, pluie, risque d'incendie, neige, pluie verglaçante,
/// chaleur, froid et UV.
List<WeatherAlert> deriveAlerts(
  ForecastBundle bundle, {
  required String zone,
  required UnitFormatter format,
}) {
  final hours = bundle.hourly;
  final alerts = <WeatherAlert>[];

  WeatherAlert build({
    required String kind,
    required _Window window,
    required String title,
    required AlertSeverity severity,
    required String summary,
    required String criteria,
  }) {
    return WeatherAlert(
      id: '$kind-${window.start.toIso8601String()}',
      title: title,
      summary: summary,
      zone: '$zone et environs',
      source: alertSource,
      severity: severity,
      startsAt: window.start,
      endsAt: window.end,
      originalText: criteria,
    );
  }

  for (final w in _windows(
    hours,
    (h) => h.condition == WeatherCondition.thunderstorm,
  )) {
    final gust = w.max(hours, (h) => h.windGust);
    final hail = w.any(hours, (h) => h.weatherCode >= 96);
    final severe = hail || gust >= 70;
    alerts.add(
      build(
        kind: 'storm',
        window: w,
        title: severe ? 'Alerte orages violents' : "Risque d'orages",
        severity: severe ? AlertSeverity.danger : AlertSeverity.vigilance,
        summary:
            "Orages attendus${hail ? ' avec risque de grêle' : ''}, rafales "
            "jusqu'à ${format.windSpeed(gust)}. Évitez les déplacements non "
            'essentiels et abritez-vous dans un bâtiment.',
        criteria:
            'Code météo WMO orageux (95–99) prévu. Rafale maximale prévue : '
            '${format.windSpeed(gust)}.',
      ),
    );
  }

  for (final w in _windows(hours, (h) => h.windGust >= 60)) {
    final gust = w.max(hours, (h) => h.windGust);
    final severity = gust >= 120
        ? AlertSeverity.extreme
        : gust >= 90
        ? AlertSeverity.danger
        : AlertSeverity.vigilance;
    alerts.add(
      build(
        kind: 'wind',
        window: w,
        title: severity == AlertSeverity.vigilance
            ? 'Vent fort'
            : 'Vent violent',
        severity: severity,
        summary:
            "Rafales pouvant atteindre ${format.windSpeed(gust)}. Rentrez ou "
            'fixez les objets susceptibles d’être emportés.',
        criteria:
            'Rafales ≥ ${format.windSpeed(60)} prévues '
            '(max ${format.windSpeed(gust)}).',
      ),
    );
  }

  for (final w in _windows(hours, (h) => h.precipitation >= 7.5)) {
    final peak = w.max(hours, (h) => h.precipitation);
    final total = w.sum(hours, (h) => h.precipitation);
    final severe = peak >= 15 || total >= 50;
    alerts.add(
      build(
        kind: 'rain',
        window: w,
        title: severe ? 'Pluies intenses' : 'Fortes pluies',
        severity: severe ? AlertSeverity.danger : AlertSeverity.vigilance,
        summary:
            'Pluies soutenues, cumul prévu de ${format.precipitation(total)}. '
            'Risque de ruissellement : ne vous engagez pas sur une route inondée.',
        criteria:
            'Intensité ≥ ${format.precipitation(7.5)}/h '
            '(pic ${format.precipitation(peak)}/h).',
      ),
    );
  }

  // Pluie ordinaire : les épisodes orageux ou intenses ont déjà leur alerte.
  for (final w in _windows(hours, (h) => h.precipitation >= 0.2)) {
    if (w.max(hours, (h) => h.precipitation) >= 7.5 ||
        w.any(hours, (h) => h.condition == WeatherCondition.thunderstorm)) {
      continue;
    }
    final total = w.sum(hours, (h) => h.precipitation);
    final chance = w.max(hours, (h) => h.precipitationProbability.toDouble());
    alerts.add(
      build(
        kind: 'shower',
        window: w,
        title: 'Pluie prévue',
        severity: AlertSeverity.information,
        summary:
            'Pluie attendue, cumul prévu de ${format.precipitation(total)} '
            '(probabilité jusqu’à ${chance.round()} %). Prévoyez un parapluie '
            'et roulez prudemment sur chaussée mouillée.',
        criteria: 'Précipitations ≥ ${format.precipitation(0.2)}/h prévues.',
      ),
    );
  }

  // Temps propice aux feux : chaud, sec et venté, sans pluie.
  bool fireWeather(HourlyForecast h) =>
      h.temperature >= 30 &&
      h.humidity <= 30 &&
      (h.windSpeed >= 20 || h.windGust >= 40) &&
      h.precipitation == 0;
  for (final w in _windows(hours, fireWeather)) {
    final severe = w.any(
      hours,
      (h) =>
          h.temperature >= 35 &&
          h.humidity <= 20 &&
          (h.windSpeed >= 30 || h.windGust >= 55),
    );
    final temp = w.max(hours, (h) => h.temperature);
    final wind = w.max(hours, (h) => h.windGust);
    alerts.add(
      build(
        kind: 'fire',
        window: w,
        title: severe ? "Risque d'incendie très élevé" : "Risque d'incendie",
        severity: severe ? AlertSeverity.danger : AlertSeverity.vigilance,
        summary:
            'Air chaud et sec (${format.temperatureWithUnit(temp)}) avec '
            "rafales jusqu'à ${format.windSpeed(wind)} : un départ de feu peut "
            'se propager très vite. Pas de feu, de barbecue ni de mégot en '
            'extérieur ; en cas de fumée, appelez les secours.',
        criteria:
            'Température ≥ ${format.temperatureWithUnit(30)}, humidité ≤ 30 % '
            'et vent ≥ ${format.windSpeed(20)} (ou rafales ≥ '
            '${format.windSpeed(40)}), sans pluie.',
      ),
    );
  }

  for (final w in _windows(
    hours,
    (h) => h.condition == WeatherCondition.snow,
  )) {
    alerts.add(
      build(
        kind: 'snow',
        window: w,
        title: 'Chutes de neige',
        severity: AlertSeverity.vigilance,
        summary: 'Neige attendue : routes glissantes, prudence sur la route.',
        criteria: 'Code météo WMO neige (71–77, 85–86) prévu.',
      ),
    );
  }

  for (final w in _windows(
    hours,
    (h) => h.condition == WeatherCondition.freezingRain,
  )) {
    alerts.add(
      build(
        kind: 'ice',
        window: w,
        title: 'Pluie verglaçante',
        severity: AlertSeverity.danger,
        summary:
            'Risque de verglas généralisé. Limitez vos déplacements et '
            'redoublez de prudence à pied.',
        criteria: 'Code météo WMO pluie/bruine verglaçante (56, 57, 66, 67).',
      ),
    );
  }

  for (final day in bundle.daily.take(2)) {
    final dayWindow = _Window(
      DateTime(day.date.year, day.date.month, day.date.day, 11),
      DateTime(day.date.year, day.date.month, day.date.day, 19),
    );
    if (day.maximumTemperature >= 35) {
      final severe = day.maximumTemperature >= 40;
      alerts.add(
        build(
          kind: 'heat',
          window: dayWindow,
          title: severe ? 'Canicule' : 'Fortes chaleurs',
          severity: severe ? AlertSeverity.danger : AlertSeverity.vigilance,
          summary:
              'Jusqu’à ${format.temperatureWithUnit(day.maximumTemperature)}. '
              'Hydratez-vous et évitez les efforts aux heures chaudes.',
          criteria: 'Température maximale ≥ ${format.temperatureWithUnit(35)}.',
        ),
      );
    }
    if (day.minimumTemperature <= -5) {
      alerts.add(
        build(
          kind: 'cold',
          window: _Window(
            DateTime(day.date.year, day.date.month, day.date.day),
            DateTime(day.date.year, day.date.month, day.date.day, 10),
          ),
          title: 'Grand froid',
          severity: AlertSeverity.vigilance,
          summary:
              'Minimales de ${format.temperatureWithUnit(day.minimumTemperature)}. '
              'Couvrez-vous et protégez les personnes fragiles.',
          criteria: 'Température minimale ≤ ${format.temperatureWithUnit(-5)}.',
        ),
      );
    }
    if (day.uvIndex >= 8) {
      alerts.add(
        build(
          kind: 'uv',
          window: dayWindow,
          title: day.uvIndex >= 11
              ? 'Indice UV extrême'
              : 'Indice UV très élevé',
          severity: day.uvIndex >= 11
              ? AlertSeverity.vigilance
              : AlertSeverity.information,
          summary:
              'Indice UV maximal de ${day.uvIndex.round()}. Évitez le soleil '
              'entre 12h et 16h, portez chapeau et crème solaire.',
          criteria: 'Indice UV maximal ≥ 8.',
        ),
      );
    }
  }

  alerts.sort(compareAlerts);
  return alerts;
}

class _Window {
  const _Window(this.start, this.end, [this.from = 0, this.to = 0]);

  final DateTime start;
  final DateTime end;
  final int from;
  final int to;

  double max(List<HourlyForecast> h, double Function(HourlyForecast) f) =>
      h.sublist(from, to + 1).map(f).fold(0, math.max);

  double sum(List<HourlyForecast> h, double Function(HourlyForecast) f) =>
      h.sublist(from, to + 1).map(f).fold(0, (a, b) => a + b);

  bool any(List<HourlyForecast> h, bool Function(HourlyForecast) f) =>
      h.sublist(from, to + 1).any(f);
}

/// Regroupe les heures consécutives qui vérifient [test].
List<_Window> _windows(
  List<HourlyForecast> hours,
  bool Function(HourlyForecast) test,
) {
  final windows = <_Window>[];
  int? start;
  for (var i = 0; i <= hours.length; i++) {
    final matches = i < hours.length && test(hours[i]);
    if (matches) {
      start ??= i;
    } else if (start != null) {
      windows.add(
        _Window(
          hours[start].time,
          hours[i - 1].time.add(const Duration(hours: 1)),
          start,
          i - 1,
        ),
      );
      start = null;
    }
  }
  return windows;
}
