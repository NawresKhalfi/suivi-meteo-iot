import '../../astronomy/domain/astronomy_snapshot.dart';
import '../../forecast/domain/daily_forecast.dart';
import '../../forecast/domain/hourly_forecast.dart';
import 'weather_snapshot.dart';

/// Tout ce que l'application affiche pour une ville, issu d'un seul appel.
class ForecastBundle {
  const ForecastBundle({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final WeatherSnapshot current;

  /// Heures à venir à partir de l'heure courante (jusqu'à 48 h).
  final List<HourlyForecast> hourly;

  /// 10 jours à partir d'aujourd'hui.
  final List<DailyForecast> daily;

  List<HourlyForecast> get next24Hours => hourly.take(24).toList();

  DailyForecast get today => daily.first;

  AstronomySnapshot get astronomy => AstronomySnapshot(
    sunrise: today.sunrise,
    sunset: today.sunset,
    moonPhase: moonPhaseForDate(current.observedAt),
    observedAt: current.observedAt,
  );
}
