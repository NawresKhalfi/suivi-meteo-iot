enum WeatherCondition { sunny, cloudy, rainy }

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.windSpeed,
    required this.windDirection,
    required this.humidity,
    required this.pressure,
    required this.uvIndex,
    required this.visibility,
    required this.dewPoint,
    required this.elevation,
    required this.updatedAt,
    this.isOffline = false,
  });

  final String city;
  final double temperature;
  final WeatherCondition condition;
  final double windSpeed;
  final String windDirection;
  final double humidity;
  final double pressure;
  final double uvIndex;
  final double visibility;
  final double dewPoint;
  final double elevation;
  final DateTime updatedAt;
  final bool isOffline;

  WeatherSnapshot copyWith({bool? isOffline}) {
    return WeatherSnapshot(
      city: city,
      temperature: temperature,
      condition: condition,
      windSpeed: windSpeed,
      windDirection: windDirection,
      humidity: humidity,
      pressure: pressure,
      uvIndex: uvIndex,
      visibility: visibility,
      dewPoint: dewPoint,
      elevation: elevation,
      updatedAt: updatedAt,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
