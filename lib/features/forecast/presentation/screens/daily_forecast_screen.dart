import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/daily_forecast_controller.dart';
import '../../domain/daily_forecast.dart';
import '../../../weather/domain/weather_snapshot.dart';

class DailyForecastScreen extends ConsumerWidget {
  const DailyForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(dailyForecastControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prévisions sur 10 jours'),
        actions: [
          IconButton(
            onPressed: () => context.go('/forecast/rain'),
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Probabilité de pluie',
          ),
          IconButton(
            onPressed: () => context.go('/forecast/wind'),
            icon: const Icon(Icons.air),
            tooltip: 'Vent sur 10 jours',
          ),
        ],
      ),
      body: forecast.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(dailyForecastControllerProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () =>
              ref.read(dailyForecastControllerProvider.notifier).refresh(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _DailyForecastTile(forecast: items[index], index: index),
          ),
        ),
      ),
    );
  }
}

class _DailyForecastTile extends StatelessWidget {
  const _DailyForecastTile({required this.forecast, required this.index});

  final DailyForecast forecast;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/forecast/hourly'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      index == 0 ? "Aujourd'hui" : _dayLabel(forecast.date),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(_conditionIcon(forecast.condition), size: 28),
                  const SizedBox(width: 10),
                  Text(
                    '${forecast.minimumTemperature.toStringAsFixed(0)}° / '
                    '${forecast.maximumTemperature.toStringAsFixed(0)}°C',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text('Pluie ${forecast.rainProbability}%'),
                  Text('Neige ${forecast.snowProbability}%'),
                  Text('Verglas ${forecast.iceProbability}%'),
                  Text('Foudre ${forecast.lightningProbability}%'),
                  Text('Coucher ${_timeLabel(forecast.sunset)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dayLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  static String _timeLabel(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

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
}
