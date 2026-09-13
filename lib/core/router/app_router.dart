import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/screens/alerts_screen.dart';
import '../../features/air_quality/presentation/screens/air_quality_screen.dart';
import '../../features/astronomy/presentation/screens/astronomy_screen.dart';
import '../../features/cities/presentation/screens/cities_screen.dart';
import '../../features/forecast/presentation/screens/hourly_forecast_screen.dart';
import '../../features/forecast/presentation/screens/daily_forecast_screen.dart';
import '../../features/forecast/presentation/screens/rain_probability_screen.dart';
import '../../features/radar/presentation/screens/radar_screen.dart';
import '../../features/wind/presentation/screens/wind_forecast_screen.dart';
import '../../features/weather/presentation/screens/weather_home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WeatherHomeScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/cities',
        builder: (context, state) => const CitiesScreen(),
      ),
      GoRoute(
        path: '/air-quality',
        builder: (context, state) => const AirQualityScreen(),
      ),
      GoRoute(
        path: '/astronomy',
        builder: (context, state) => const AstronomyScreen(),
      ),
      GoRoute(
        path: '/forecast/hourly',
        builder: (context, state) => const HourlyForecastScreen(),
      ),
      GoRoute(
        path: '/forecast/daily',
        builder: (context, state) => const DailyForecastScreen(),
      ),
      GoRoute(
        path: '/forecast/rain',
        builder: (context, state) => const RainProbabilityScreen(),
      ),
      GoRoute(
        path: '/radar',
        builder: (context, state) =>
            RadarScreen(layer: state.uri.queryParameters['layer'] ?? 'rain'),
      ),
      GoRoute(
        path: '/forecast/wind',
        builder: (context, state) => const WindForecastScreen(),
      ),
    ],
  );
});
