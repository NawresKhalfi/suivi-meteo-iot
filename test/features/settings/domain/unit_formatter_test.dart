import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/settings/domain/unit_formatter.dart';
import 'package:meteo/features/settings/domain/unit_settings.dart';

void main() {
  const metric = UnitFormatter(UnitSettings());

  test('valeurs par défaut métriques', () {
    expect(metric.temperature(24.4), '24°');
    expect(metric.temperatureWithUnit(24.6), '25 °C');
    expect(metric.windSpeed(14.2), '14 km/h');
    expect(metric.pressure(1019.3), '1019 hPa');
    expect(metric.visibility(40420), '40 km');
    expect(metric.visibility(4200), '4,2 km');
    expect(metric.precipitation(5.8), '5,8 mm');
    expect(metric.time(DateTime(2026, 9, 27, 19, 42)), '19:42');
    expect(metric.hour(DateTime(2026, 9, 27, 9)), '9h');
    expect(metric.date(DateTime(2026, 9, 5)), '05/09/2026');
  });

  test('conversions impériales et formats alternatifs', () {
    const format = UnitFormatter(
      UnitSettings(
        temperature: TemperatureUnit.fahrenheit,
        windSpeed: WindSpeedUnit.mph,
        pressure: PressureUnit.mmHg,
        visibility: VisibilityUnit.miles,
        precipitation: PrecipitationUnit.inches,
        timeFormat: TimeFormat.h12,
        datePattern: DatePattern.ymd,
      ),
    );
    expect(format.temperature(0), '32°');
    expect(format.temperature(24), '75°');
    expect(format.windSpeed(16.09344), '10 mph');
    expect(format.pressure(1013.25), '760 mmHg');
    expect(format.visibility(16093.44), '10 mi');
    expect(format.precipitation(25.4), '1,00 in');
    expect(format.time(DateTime(2026, 1, 1, 19, 5)), '7:05 PM');
    expect(format.time(DateTime(2026, 1, 1, 0, 30)), '12:30 AM');
    expect(format.hour(DateTime(2026, 1, 1, 14)), '2 PM');
    expect(format.date(DateTime(2026, 9, 5)), '2026/09/05');
  });

  test('m/s, nœuds, bar et atm', () {
    expect(
      const UnitFormatter(
        UnitSettings(windSpeed: WindSpeedUnit.ms),
      ).windSpeed(18),
      '5,0 m/s',
    );
    expect(
      const UnitFormatter(
        UnitSettings(windSpeed: WindSpeedUnit.knots),
      ).windSpeed(18.52),
      '10 kn',
    );
    expect(
      const UnitFormatter(
        UnitSettings(pressure: PressureUnit.bar),
      ).pressure(1013),
      '1,013 bar',
    );
    expect(
      const UnitFormatter(
        UnitSettings(pressure: PressureUnit.atm),
      ).pressure(1013.25),
      '1,000 atm',
    );
  });

  test('sérialisation des réglages', () {
    const settings = UnitSettings(
      temperature: TemperatureUnit.fahrenheit,
      datePattern: DatePattern.mdy,
      dailySummaryEnabled: false,
    );
    final restored = UnitSettings.fromJson(settings.toJson());
    expect(restored.temperature, TemperatureUnit.fahrenheit);
    expect(restored.datePattern, DatePattern.mdy);
    expect(restored.dailySummaryEnabled, isFalse);
    expect(
      UnitSettings.fromJson({'temperature': 'inconnu'}).temperature,
      TemperatureUnit.celsius,
    );
  });
}
