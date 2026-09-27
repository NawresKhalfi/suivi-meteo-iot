import 'unit_settings.dart';

/// Convertit et formate les valeurs météo (toujours reçues en unités
/// métriques : °C, km/h, hPa, mètres, mm) selon les réglages utilisateur.
class UnitFormatter {
  const UnitFormatter(this.settings);

  final UnitSettings settings;

  double convertTemperature(double celsius) =>
      settings.temperature == TemperatureUnit.fahrenheit
      ? celsius * 9 / 5 + 32
      : celsius;

  /// « 24° »
  String temperature(double celsius) =>
      '${convertTemperature(celsius).round()}°';

  /// « 24 °C »
  String temperatureWithUnit(double celsius) =>
      '${convertTemperature(celsius).round()} '
      '${settings.temperature == TemperatureUnit.fahrenheit ? '°F' : '°C'}';

  double convertWindSpeed(double kmh) => switch (settings.windSpeed) {
    WindSpeedUnit.kmh => kmh,
    WindSpeedUnit.mph => kmh / 1.609344,
    WindSpeedUnit.ms => kmh / 3.6,
    WindSpeedUnit.knots => kmh / 1.852,
  };

  String get windSpeedUnit => switch (settings.windSpeed) {
    WindSpeedUnit.kmh => 'km/h',
    WindSpeedUnit.mph => 'mph',
    WindSpeedUnit.ms => 'm/s',
    WindSpeedUnit.knots => 'kn',
  };

  String windSpeed(double kmh) {
    final value = convertWindSpeed(kmh);
    final text = settings.windSpeed == WindSpeedUnit.ms && value < 10
        ? _decimal(value, 1)
        : value.round().toString();
    return '$text $windSpeedUnit';
  }

  String pressure(double hPa) => switch (settings.pressure) {
    PressureUnit.hPa => '${hPa.round()} hPa',
    PressureUnit.bar => '${_decimal(hPa / 1000, 3)} bar',
    PressureUnit.atm => '${_decimal(hPa / 1013.25, 3)} atm',
    PressureUnit.mmHg => '${(hPa * 0.750062).round()} mmHg',
  };

  String visibility(double meters) {
    switch (settings.visibility) {
      case VisibilityUnit.meters:
        return '${meters.round()} m';
      case VisibilityUnit.kilometers:
        final km = meters / 1000;
        return '${km < 10 ? _decimal(km, 1) : km.round()} km';
      case VisibilityUnit.miles:
        final miles = meters / 1609.344;
        return '${miles < 10 ? _decimal(miles, 1) : miles.round()} mi';
    }
  }

  String precipitation(double millimeters) => switch (settings.precipitation) {
    PrecipitationUnit.millimeters => '${_decimal(millimeters, 1)} mm',
    PrecipitationUnit.centimeters => '${_decimal(millimeters / 10, 2)} cm',
    PrecipitationUnit.inches => '${_decimal(millimeters / 25.4, 2)} in',
  };

  /// Heure et minutes : « 19:42 » ou « 7:42 PM ».
  String time(DateTime value) {
    final minutes = value.minute.toString().padLeft(2, '0');
    if (settings.timeFormat == TimeFormat.h24) {
      return '${value.hour.toString().padLeft(2, '0')}:$minutes';
    }
    return '${_hour12(value.hour)}:$minutes ${_suffix(value.hour)}';
  }

  /// Heure ronde courte : « 14h » ou « 2 PM ».
  String hour(DateTime value) => settings.timeFormat == TimeFormat.h24
      ? '${value.hour}h'
      : '${_hour12(value.hour)} ${_suffix(value.hour)}';

  String date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return switch (settings.datePattern) {
      DatePattern.dmy => '$day/$month/$year',
      DatePattern.mdy => '$month/$day/$year',
      DatePattern.ymd => '$year/$month/$day',
    };
  }

  String dateTime(DateTime value) => '${date(value)}, ${time(value)}';

  static int _hour12(int hour) => hour % 12 == 0 ? 12 : hour % 12;
  static String _suffix(int hour) => hour < 12 ? 'AM' : 'PM';

  /// Décimales avec virgule française.
  static String _decimal(double value, int digits) =>
      value.toStringAsFixed(digits).replaceAll('.', ',');
}
