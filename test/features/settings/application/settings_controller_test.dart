import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/core/storage/local_preferences.dart';
import 'package:meteo/features/settings/application/settings_controller.dart';
import 'package:meteo/features/settings/data/settings_store.dart';
import 'package:meteo/features/settings/domain/unit_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsController (US30 à US33)', () {
    late MemorySettingsStore store;
    late ProviderContainer container;

    setUp(() {
      store = MemorySettingsStore();
      container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
    });
    tearDown(() => container.dispose());

    test('réglages métriques par défaut', () {
      final settings = container.read(settingsControllerProvider);
      expect(settings.temperature, TemperatureUnit.celsius);
      expect(settings.windSpeed, WindSpeedUnit.kmh);
      expect(settings.timeFormat, TimeFormat.h24);
      expect(settings.datePattern, DatePattern.dmy);
      expect(settings.dailySummaryEnabled, isTrue);
    });

    test('une modification est persistée et suivie par le formateur', () async {
      final formatter = container.read(unitFormatterProvider);
      expect(formatter.windSpeed(36), '36 km/h');

      await container
          .read(settingsControllerProvider.notifier)
          .update(
            (s) => s.copyWith(
              windSpeed: WindSpeedUnit.ms,
              timeFormat: TimeFormat.h12,
              datePattern: DatePattern.ymd,
            ),
          );
      expect(store.value.windSpeed, WindSpeedUnit.ms);
      final updated = container.read(unitFormatterProvider);
      expect(updated.windSpeed(36), '10 m/s');
      expect(updated.time(DateTime(2026, 9, 27, 18, 6)), '6:06 PM');
      expect(updated.date(DateTime(2026, 9, 27)), '2026/09/27');
    });

    test('les réglages enregistrés sont relus au démarrage', () {
      store.value = const UnitSettings(pressure: PressureUnit.mmHg);
      final next = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(next.dispose);
      expect(next.read(settingsControllerProvider).pressure, PressureUnit.mmHg);
    });

    test('US33 : activer / désactiver le résumé quotidien', () async {
      final controller = container.read(settingsControllerProvider.notifier);
      await controller.update((s) => s.copyWith(dailySummaryEnabled: false));
      expect(store.value.dailySummaryEnabled, isFalse);
      await controller.update((s) => s.copyWith(dailySummaryEnabled: true));
      expect(store.value.dailySummaryEnabled, isTrue);
    });
  });

  group('SharedPreferencesSettingsStore', () {
    Future<SharedPreferencesSettingsStore> store([
      Map<String, Object> values = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(values);
      return SharedPreferencesSettingsStore(
        LocalPreferences(await SharedPreferences.getInstance()),
      );
    }

    test('valeurs par défaut sans données', () async {
      expect((await store()).read().temperature, TemperatureUnit.celsius);
    });

    test('enregistre puis relit les réglages', () async {
      final s = await store();
      await s.save(
        const UnitSettings(
          visibility: VisibilityUnit.miles,
          precipitation: PrecipitationUnit.inches,
        ),
      );
      final read = s.read();
      expect(read.visibility, VisibilityUnit.miles);
      expect(read.precipitation, PrecipitationUnit.inches);
    });

    test('des données corrompues donnent les valeurs par défaut', () async {
      final read = (await store({'settings.units': 'pas du json'})).read();
      expect(read.temperature, TemperatureUnit.celsius);
    });
  });
}
