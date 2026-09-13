import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/hourly_forecast_controller.dart';
import '../../domain/hourly_forecast.dart';
import '../../../weather/domain/weather_snapshot.dart';

class HourlyForecastScreen extends ConsumerWidget {
  const HourlyForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(hourlyForecastControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Prévisions sur 24 heures')),
      body: forecast.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(hourlyForecastControllerProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () =>
              ref.read(hourlyForecastControllerProvider.notifier).refresh(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _ForecastHourTile(forecast: items[index], index: index),
          ),
        ),
      ),
    );
  }
}

class _ForecastHourTile extends StatelessWidget {
  const _ForecastHourTile({required this.forecast, required this.index});

  final HourlyForecast forecast;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                index == 0 ? 'Maint.' : _formatHour(forecast.time),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(_conditionIcon(forecast.condition), size: 28),
            const SizedBox(width: 10),
            SizedBox(
              width: 62,
              child: Text('${forecast.temperature.toStringAsFixed(1)} °C'),
            ),
            Expanded(
              child: Text(
                '${_precipitationLabel(forecast.precipitationType)} '
                '${forecast.precipitationProbability}%\n'
                'Vent ${forecast.windSpeed.toStringAsFixed(0)} km/h, '
                'raf. ${forecast.windGust.toStringAsFixed(0)} ${forecast.windDirection}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatHour(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')} h';

  static IconData _conditionIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny_outlined;
      case WeatherCondition.cloudy:
        return Icons.cloud_outlined;
      case WeatherCondition.rainy:
        return Icons.water_drop_outlined;
    }
  }

  static String _precipitationLabel(PrecipitationType type) {
    switch (type) {
      case PrecipitationType.none:
        return 'Précip.';
      case PrecipitationType.rain:
        return 'Pluie';
      case PrecipitationType.snow:
        return 'Neige';
      case PrecipitationType.ice:
        return 'Verglas';
    }
  }
}
