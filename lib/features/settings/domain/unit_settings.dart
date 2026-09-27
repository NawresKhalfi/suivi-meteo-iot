/// Préférences d'unités et de formats (E11 – US30 à US32).
enum TemperatureUnit {
  celsius('Celsius (°C)'),
  fahrenheit('Fahrenheit (°F)');

  const TemperatureUnit(this.label);
  final String label;
}

enum PrecipitationUnit {
  millimeters('Millimètres (mm)'),
  inches('Pouces (in)'),
  centimeters('Centimètres (cm)');

  const PrecipitationUnit(this.label);
  final String label;
}

enum VisibilityUnit {
  kilometers('Kilomètres (km)'),
  meters('Mètres (m)'),
  miles('Miles (mi)');

  const VisibilityUnit(this.label);
  final String label;
}

enum WindSpeedUnit {
  kmh('km/h'),
  mph('mph'),
  ms('m/s'),
  knots('Nœuds (kn)');

  const WindSpeedUnit(this.label);
  final String label;
}

enum PressureUnit {
  hPa('hPa'),
  bar('bar'),
  atm('atm'),
  mmHg('mmHg');

  const PressureUnit(this.label);
  final String label;
}

enum TimeFormat {
  h24('24 heures'),
  h12('12 heures');

  const TimeFormat(this.label);
  final String label;
}

enum DatePattern {
  dmy('jj/mm/aaaa'),
  mdy('mm/jj/aaaa'),
  ymd('aaaa/mm/jj');

  const DatePattern(this.label);
  final String label;
}

class UnitSettings {
  const UnitSettings({
    this.temperature = TemperatureUnit.celsius,
    this.precipitation = PrecipitationUnit.millimeters,
    this.visibility = VisibilityUnit.kilometers,
    this.windSpeed = WindSpeedUnit.kmh,
    this.pressure = PressureUnit.hPa,
    this.timeFormat = TimeFormat.h24,
    this.datePattern = DatePattern.dmy,
    this.dailySummaryEnabled = true,
  });

  final TemperatureUnit temperature;
  final PrecipitationUnit precipitation;
  final VisibilityUnit visibility;
  final WindSpeedUnit windSpeed;
  final PressureUnit pressure;
  final TimeFormat timeFormat;
  final DatePattern datePattern;
  final bool dailySummaryEnabled;

  UnitSettings copyWith({
    TemperatureUnit? temperature,
    PrecipitationUnit? precipitation,
    VisibilityUnit? visibility,
    WindSpeedUnit? windSpeed,
    PressureUnit? pressure,
    TimeFormat? timeFormat,
    DatePattern? datePattern,
    bool? dailySummaryEnabled,
  }) {
    return UnitSettings(
      temperature: temperature ?? this.temperature,
      precipitation: precipitation ?? this.precipitation,
      visibility: visibility ?? this.visibility,
      windSpeed: windSpeed ?? this.windSpeed,
      pressure: pressure ?? this.pressure,
      timeFormat: timeFormat ?? this.timeFormat,
      datePattern: datePattern ?? this.datePattern,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
    );
  }

  Map<String, Object> toJson() => {
    'temperature': temperature.name,
    'precipitation': precipitation.name,
    'visibility': visibility.name,
    'windSpeed': windSpeed.name,
    'pressure': pressure.name,
    'timeFormat': timeFormat.name,
    'datePattern': datePattern.name,
    'dailySummaryEnabled': dailySummaryEnabled,
  };

  factory UnitSettings.fromJson(Map<String, dynamic> json) {
    T pick<T extends Enum>(List<T> values, String key, T fallback) {
      final name = json[key];
      return values.firstWhere((v) => v.name == name, orElse: () => fallback);
    }

    const defaults = UnitSettings();
    return UnitSettings(
      temperature: pick(
        TemperatureUnit.values,
        'temperature',
        defaults.temperature,
      ),
      precipitation: pick(
        PrecipitationUnit.values,
        'precipitation',
        defaults.precipitation,
      ),
      visibility: pick(
        VisibilityUnit.values,
        'visibility',
        defaults.visibility,
      ),
      windSpeed: pick(WindSpeedUnit.values, 'windSpeed', defaults.windSpeed),
      pressure: pick(PressureUnit.values, 'pressure', defaults.pressure),
      timeFormat: pick(TimeFormat.values, 'timeFormat', defaults.timeFormat),
      datePattern: pick(
        DatePattern.values,
        'datePattern',
        defaults.datePattern,
      ),
      dailySummaryEnabled: json['dailySummaryEnabled'] as bool? ?? true,
    );
  }
}
