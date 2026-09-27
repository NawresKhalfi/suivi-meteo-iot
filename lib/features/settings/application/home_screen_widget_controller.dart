import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cities/application/cities_controller.dart';
import '../../weather/application/weather_controller.dart';
import '../data/home_screen_widget.dart';
import 'settings_controller.dart';

final homeScreenWidgetServiceProvider = Provider<HomeScreenWidgetService>(
  (ref) => const UnsupportedHomeScreenWidgetService(),
);

/// Tient le widget à jour pendant que l'app est ouverte, quand la ville
/// affichée est la ville par défaut (celle que montre le widget).
final homeScreenWidgetSyncProvider = Provider<void>((ref) {
  final bundle = ref.watch(weatherControllerProvider).valueOrNull;
  final cities = ref.watch(citiesControllerProvider);
  final format = ref.watch(unitFormatterProvider);
  final city = cities.selectedCity;
  if (bundle == null || !cities.isDefault(city)) return;
  unawaited(
    ref
        .read(homeScreenWidgetServiceProvider)
        .update(HomeScreenWidgetData.from(city, bundle.current, format))
        .catchError((Object e) => debugPrint('Widget non mis à jour : $e')),
  );
});

/// Écrit la météo de la ville par défaut puis demande au système d'épingler
/// le widget (fenêtre de confirmation Android).
Future<void> pinHomeScreenWidget(WidgetRef ref) async {
  final service = ref.read(homeScreenWidgetServiceProvider);
  final cities = ref.read(citiesControllerProvider);
  final city = cities.defaultCityOrFirst;
  final loaded = ref.read(weatherControllerProvider).valueOrNull;
  try {
    final bundle = cities.selectedCity == city && loaded != null
        ? loaded
        : await ref.read(weatherRepositoryProvider).fetchForecast(city);
    await service.update(
      HomeScreenWidgetData.from(
        city,
        bundle.current,
        ref.read(unitFormatterProvider),
      ),
    );
  } on Object catch (e) {
    // Le widget affichera « Ouvrez l'app… » jusqu'au prochain rafraîchissement.
    debugPrint('Météo du widget indisponible : $e');
  }
  await service.requestPin();
}
