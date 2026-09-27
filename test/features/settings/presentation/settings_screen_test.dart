import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/alerts/application/alerts_controller.dart';
import 'package:meteo/features/alerts/data/alerts_repository.dart';
import 'package:meteo/features/settings/application/home_screen_widget_controller.dart';
import 'package:meteo/features/settings/application/settings_controller.dart';
import 'package:meteo/features/settings/data/settings_store.dart';
import 'package:meteo/features/settings/domain/unit_settings.dart';

import '../../../helpers/pump_app.dart';

/// E11 — Unités et formats ; E12 — Notifications et widget.
void main() {
  late MemorySettingsStore store;

  setUp(() => store = MemorySettingsStore());

  Future<void> openSettings(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await pumpApp(
      tester,
      overrides: [settingsStoreProvider.overrideWithValue(store), ...overrides],
    );
    await openTab(tester, 'Réglages');
  }

  Future<void> pick(WidgetTester tester, String row, String option) async {
    await tapVisible(tester, find.text(row));
    await tester.tap(find.text(option).last);
    await settle(tester);
  }

  testWidgets('affiche les valeurs par défaut de chaque réglage', (
    tester,
  ) async {
    await openSettings(tester);
    expect(find.text('Unités de mesure'), findsOneWidget);
    expect(find.text('Celsius (°C)'), findsOneWidget);
    expect(find.text('Millimètres (mm)'), findsOneWidget);
    expect(find.text('Kilomètres (km)'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
    expect(find.text('hPa'), findsOneWidget);
    expect(find.text('24 heures'), findsOneWidget);
    expect(find.text('jj/mm/aaaa'), findsOneWidget);
  });

  testWidgets('US30 : vitesse du vent en m/s appliquée à l’accueil', (
    tester,
  ) async {
    await openSettings(tester);
    await pick(tester, 'Vitesse du vent', 'm/s');
    expect(find.text('Vitesse du vent mis à jour : m/s'), findsOneWidget);
    expect(store.value.windSpeed, WindSpeedUnit.ms);

    await openTab(tester, 'Accueil');
    expect(find.text('4,1 m/s'), findsWidgets); // 14,9 km/h
  });

  testWidgets('US30 : pression, précipitations et visibilité', (tester) async {
    await openSettings(tester);
    await pick(tester, 'Pression', 'bar');
    expect(store.value.pressure, PressureUnit.bar);
    await pick(tester, 'Précipitations', 'Pouces (in)');
    expect(store.value.precipitation, PrecipitationUnit.inches);
    await pick(tester, 'Visibilité', 'Mètres (m)');
    expect(store.value.visibility, VisibilityUnit.meters);

    await openTab(tester, 'Accueil');
    await scrollTo(tester, find.text('Élévation'));
    expect(find.text('1,019 bar'), findsOneWidget);
    expect(find.text('40420 m'), findsOneWidget);
  });

  testWidgets('choisir la même option ne change rien', (tester) async {
    await openSettings(tester);
    await pick(tester, 'Température', 'Celsius (°C)');
    expect(find.textContaining('Température mis à jour'), findsNothing);
  });

  testWidgets('US31 : format 12 heures appliqué aux horaires', (tester) async {
    await openSettings(tester);
    await pick(tester, "Format de l'heure", '12 heures');
    expect(find.text("Format de l'heure mis à jour : 12 heures"), findsOne);
    expect(store.value.timeFormat, TimeFormat.h12);

    await openTab(tester, 'Accueil');
    await scrollTo(tester, find.text('Lever à 6:08 AM'));
    expect(find.text('6:06 PM'), findsOneWidget);
  });

  testWidgets('US32 : format de date aaaa/mm/jj', (tester) async {
    await openSettings(tester);
    await pick(tester, 'Format de date', 'aaaa/mm/jj');
    expect(find.text('Format de date mis à jour : aaaa/mm/jj'), findsOneWidget);
    expect(store.value.datePattern, DatePattern.ymd);
  });

  testWidgets('US33 : activer puis désactiver les alertes météo', (
    tester,
  ) async {
    final service = UnconfiguredAlertNotificationService();
    await openSettings(
      tester,
      overrides: [alertNotificationServiceProvider.overrideWithValue(service)],
    );
    await tapVisible(tester, find.text('Alertes météo'));
    expect(find.text('Alertes météo : activées'), findsOneWidget);
    expect(service.isEnabled, isTrue);

    await tapVisible(tester, find.text('Alertes météo'));
    expect(find.text('Alertes météo : désactivées'), findsOneWidget);
    expect(service.isEnabled, isFalse);
  });

  testWidgets('US33 : désactiver le résumé quotidien', (tester) async {
    await openSettings(tester);
    await tapVisible(tester, find.text('Résumé quotidien'));
    expect(find.text('Résumé quotidien : désactivé'), findsOneWidget);
    expect(store.value.dailySummaryEnabled, isFalse);
  });

  testWidgets("US34 : aperçu du widget avec la météo de la ville par défaut", (
    tester,
  ) async {
    await openSettings(
      tester,
      overrides: [
        homeScreenWidgetServiceProvider.overrideWithValue(
          FakeHomeScreenWidgetService(),
        ),
      ],
    );
    final hint = find.text("Toucher pour l'ajouter à l'écran d'accueil");
    await scrollTo(tester, hint);
    expect(find.text("Widget d'écran d'accueil"), findsOneWidget);
    expect(find.textContaining('Nuageux · aperçu'), findsOneWidget);
  });
}
