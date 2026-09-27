import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/widgets/weather_icon.dart';
import '../../cities/domain/city.dart';
import '../../weather/domain/weather_snapshot.dart';
import '../../weather/domain/weather_condition.dart';
import '../domain/unit_formatter.dart';

/// Contenu affiché par le widget d'écran d'accueil.
class HomeScreenWidgetData {
  const HomeScreenWidgetData({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.emoji,
    required this.updatedAt,
  });

  factory HomeScreenWidgetData.from(
    City city,
    WeatherSnapshot current,
    UnitFormatter format,
  ) => HomeScreenWidgetData(
    city: city.name,
    temperature: format.temperature(current.temperature),
    condition: current.condition.label(isDay: current.isDay),
    emoji: switch (current.condition.icon(isDay: current.isDay)) {
      WeatherIconType.sun => '☀️',
      WeatherIconType.sunCloud => '⛅',
      WeatherIconType.cloud => '☁️',
      WeatherIconType.cloudRain => '🌧️',
      WeatherIconType.cloudSnow => '🌨️',
      WeatherIconType.cloudBolt => '⛈️',
      WeatherIconType.fog => '🌫️',
      WeatherIconType.moon => '🌙',
      WeatherIconType.moonCloud => '☁️',
    },
    updatedAt: format.time(DateTime.now()),
  );

  final String city;
  final String temperature;
  final String condition;
  final String emoji;
  final String updatedAt;
}

/// Implémentation adaptée à la plateforme courante.
HomeScreenWidgetService platformHomeScreenWidget() =>
    !kIsWeb && Platform.isAndroid
    ? const AndroidHomeScreenWidgetService()
    : const UnsupportedHomeScreenWidgetService();

abstract interface class HomeScreenWidgetService {
  /// Le système peut-il épingler le widget depuis l'app (Android 8+) ?
  Future<bool> canPin();

  /// Ouvre la fenêtre système de confirmation d'ajout du widget.
  Future<void> requestPin();

  /// Le widget est-il présent sur l'écran d'accueil ?
  Future<bool> isInstalled();

  Future<void> update(HomeScreenWidgetData data);
}

/// Widget Android natif (`WeatherWidgetProvider.kt`) via `home_widget`.
class AndroidHomeScreenWidgetService implements HomeScreenWidgetService {
  const AndroidHomeScreenWidgetService();

  static const _provider = 'com.example.meteo.WeatherWidgetProvider';

  @override
  Future<bool> canPin() async =>
      await HomeWidget.isRequestPinWidgetSupported() ?? false;

  @override
  Future<void> requestPin() =>
      HomeWidget.requestPinWidget(qualifiedAndroidName: _provider);

  @override
  Future<bool> isInstalled() async =>
      (await HomeWidget.getInstalledWidgets()).isNotEmpty;

  @override
  Future<void> update(HomeScreenWidgetData data) async {
    await Future.wait([
      HomeWidget.saveWidgetData('city', data.city),
      HomeWidget.saveWidgetData('temperature', data.temperature),
      HomeWidget.saveWidgetData('condition', data.condition),
      HomeWidget.saveWidgetData('emoji', data.emoji),
      HomeWidget.saveWidgetData('updated_at', data.updatedAt),
    ]);
    await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
  }
}

/// iOS (extension WidgetKit absente), web, desktop et tests.
class UnsupportedHomeScreenWidgetService implements HomeScreenWidgetService {
  const UnsupportedHomeScreenWidgetService();

  @override
  Future<bool> canPin() async => false;

  @override
  Future<void> requestPin() async {}

  @override
  Future<bool> isInstalled() async => false;

  @override
  Future<void> update(HomeScreenWidgetData data) async {}
}
