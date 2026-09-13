import '../domain/air_quality_snapshot.dart';

abstract interface class AirQualityRepository {
  Future<AirQualitySnapshot> fetchCurrentAirQuality();
}

class DemoAirQualityRepository implements AirQualityRepository {
  @override
  Future<AirQualitySnapshot> fetchCurrentAirQuality() async {
    return AirQualitySnapshot(
      city: 'Paris',
      aqi: 42,
      level: airQualityLevelForAqi(42),
      pollutants: const [
        PollutantReading(name: 'PM10', value: 18, unit: 'µg/m³'),
        PollutantReading(name: 'PM2.5', value: 9, unit: 'µg/m³'),
        PollutantReading(name: 'CO', value: 0.3, unit: 'mg/m³'),
        PollutantReading(name: 'NO2', value: 21, unit: 'µg/m³'),
        PollutantReading(name: 'SO2', value: 4, unit: 'µg/m³'),
        PollutantReading(name: 'O3', value: 57, unit: 'µg/m³'),
      ],
      updatedAt: DateTime.now(),
    );
  }
}
