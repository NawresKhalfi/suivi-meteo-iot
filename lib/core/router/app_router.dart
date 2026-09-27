import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/screens/alerts_screen.dart';
import '../../features/cities/presentation/screens/cities_screen.dart';
import '../../features/forecast/presentation/screens/forecast_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/weather/presentation/screens/home_screen.dart';
import '../shell/app_shell.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const forecast = '/forecast';
  static const map = '/map';
  static const cities = '/cities';
  static const settings = '/settings';
  static const alerts = '/alerts';
}

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  GoRoute tab(String path, Widget screen) => GoRoute(
    path: path,
    pageBuilder: (_, _) => NoTransitionPage(child: screen),
  );

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [tab(AppRoutes.home, const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [tab(AppRoutes.forecast, const ForecastScreen())],
          ),
          StatefulShellBranch(routes: [tab(AppRoutes.map, const MapScreen())]),
          StatefulShellBranch(
            routes: [tab(AppRoutes.cities, const CitiesScreen())],
          ),
          StatefulShellBranch(
            routes: [tab(AppRoutes.settings, const SettingsScreen())],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.alerts,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const AlertsScreen(),
      ),
    ],
  );
});
