import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/core/format/french_calendar.dart';
import 'package:meteo/core/widgets/weather_icon.dart';
import 'package:meteo/features/weather/domain/weather_condition.dart';

void main() {
  test('traduit les codes WMO', () {
    expect(conditionFromWmo(0), WeatherCondition.clear);
    expect(conditionFromWmo(2), WeatherCondition.partlyCloudy);
    expect(conditionFromWmo(45), WeatherCondition.fog);
    expect(conditionFromWmo(63), WeatherCondition.rain);
    expect(conditionFromWmo(67), WeatherCondition.freezingRain);
    expect(conditionFromWmo(75), WeatherCondition.snow);
    expect(conditionFromWmo(81), WeatherCondition.showers);
    expect(conditionFromWmo(99), WeatherCondition.thunderstorm);
  });

  test('icônes jour/nuit et type de précipitation', () {
    expect(WeatherCondition.clear.icon(isDay: false), WeatherIconType.moon);
    expect(WeatherCondition.partlyCloudy.icon(), WeatherIconType.sunCloud);
    expect(WeatherCondition.snow.precipitationType, PrecipitationType.snow);
    expect(
      WeatherCondition.freezingRain.precipitationType,
      PrecipitationType.ice,
    );
    expect(WeatherCondition.clear.label(isDay: false), 'Nuit claire');
  });

  test('directions cardinales françaises', () {
    expect(compassLabel(0), 'N');
    expect(compassLabel(83), 'E');
    expect(compassLabel(225), 'SO');
    expect(compassLabel(315), 'NO');
    expect(compassLabel(350), 'N');
    expect(compassName(315), 'Nord-Ouest');
  });
}
