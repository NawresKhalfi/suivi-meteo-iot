import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/cities/application/cities_controller.dart';
import 'package:meteo/features/cities/domain/city.dart';
import 'package:meteo/features/settings/application/home_screen_widget_controller.dart';
import 'package:meteo/features/settings/data/home_screen_widget.dart';
import 'package:meteo/features/settings/domain/unit_formatter.dart';
import 'package:meteo/features/settings/domain/unit_settings.dart';
import 'package:meteo/features/weather/application/weather_controller.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

const paris = City(
  name: 'Paris',
  country: 'France',
  latitude: 48.8534,
  longitude: 2.3488,
);

/// E12 — US34 : widget d'écran d'accueil.
void main() {
  test('contenu du widget : ville, température, ciel et emoji', () {
    final data = HomeScreenWidgetData.from(
      defaultCity,
      loadBundle().current,
      const UnitFormatter(UnitSettings()),
    );
    expect(data.city, 'Nabeul');
    expect(data.temperature, '26°');
    expect(data.condition, 'Nuageux');
    expect(data.emoji, '☁️');
    expect(data.updatedAt, matches(RegExp(r'^\d{2}:\d{2}$')));
  });

  test('suit les unités choisies (°F)', () {
    final data = HomeScreenWidgetData.from(
      defaultCity,
      loadBundle().current,
      const UnitFormatter(
        UnitSettings(temperature: TemperatureUnit.fahrenheit),
      ),
    );
    expect(data.temperature, '78°');
  });

  test('plateformes non prises en charge : aucune action', () async {
    const service = UnsupportedHomeScreenWidgetService();
    expect(await service.canPin(), isFalse);
    expect(await service.isInstalled(), isFalse);
    await service.requestPin();
  });

  test(
    'mis à jour avec la ville par défaut, pas avec une autre ville',
    () async {
      final widget = FakeHomeScreenWidgetService();
      final container = ProviderContainer(
        overrides: [
          ...testOverrides(),
          homeScreenWidgetServiceProvider.overrideWithValue(widget),
        ],
      );
      addTearDown(container.dispose);
      container.listen(homeScreenWidgetSyncProvider, (_, _) {});

      await container.read(weatherControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(widget.updates, hasLength(1));
      expect(widget.updates.single.city, 'Nabeul');

      final cities = container.read(citiesControllerProvider.notifier);
      await cities.addCity(paris);
      cities.select(paris);
      await container.read(weatherControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(widget.updates.map((u) => u.city), everyElement('Nabeul'));
    },
  );
}
