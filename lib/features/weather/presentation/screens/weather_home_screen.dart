import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/weather_controller.dart';
import '../../domain/weather_snapshot.dart';

class WeatherHomeScreen extends ConsumerWidget {
  const WeatherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi météo'),
        actions: [
          IconButton(
            onPressed: () => context.go('/alerts'),
            icon: const Icon(Icons.warning_amber_outlined),
            tooltip: 'Alertes météo',
          ),
          IconButton(
            onPressed: () => context.go('/air-quality'),
            icon: const Icon(Icons.air_outlined),
            tooltip: "Qualité de l'air",
          ),
          IconButton(
            onPressed: () => context.go('/astronomy'),
            icon: const Icon(Icons.wb_twilight_outlined),
            tooltip: 'Soleil et lune',
          ),
          IconButton(
            onPressed: () => context.go('/forecast/hourly'),
            icon: const Icon(Icons.schedule_outlined),
            tooltip: 'Prévisions horaires',
          ),
          IconButton(
            onPressed: () => context.go('/forecast/daily'),
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Prévisions à 10 jours',
          ),
          IconButton(
            onPressed: () => context.go('/cities'),
            icon: const Icon(Icons.location_city_outlined),
            tooltip: 'Gérer les villes',
          ),
        ],
      ),
      body: weather.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _WeatherError(
          onRetry: ref.read(weatherControllerProvider.notifier).refresh,
        ),
        data: (snapshot) => RefreshIndicator(
          onRefresh: ref.read(weatherControllerProvider.notifier).refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _CurrentWeatherCard(snapshot: snapshot),
              const SizedBox(height: 16),
              _MetricsGrid(snapshot: snapshot),
              const SizedBox(height: 16),
              Text('Dernière mise à jour : ${_formatTime(snapshot.updatedAt)}'),
              if (snapshot.isOffline)
                const Text('Hors ligne - dernière donnée connue'),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  const _CurrentWeatherCard({required this.snapshot});

  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 52),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.city,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${snapshot.temperature.toStringAsFixed(1)} °C',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const Text('Ensoleillé'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.snapshot});

  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        'Vent',
        '${snapshot.windSpeed} km/h ${snapshot.windDirection}',
        Icons.air,
      ),
      ('Humidité', '${snapshot.humidity} %', Icons.water_drop_outlined),
      ('Pression', '${snapshot.pressure} hPa', Icons.speed),
      (
        'Indice UV',
        snapshot.uvIndex.toStringAsFixed(1),
        Icons.wb_sunny_outlined,
      ),
      ('Visibilité', '${snapshot.visibility} km', Icons.visibility_outlined),
      ('Point de rosée', '${snapshot.dewPoint} °C', Icons.thermostat),
      ('Élévation', '${snapshot.elevation} m', Icons.terrain),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics
          .map(
            (metric) => SizedBox(
              width: 155,
              child: Card(
                child: ListTile(
                  dense: true,
                  leading: Icon(metric.$3),
                  title: Text(metric.$1),
                  subtitle: Text(metric.$2),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _WeatherError extends StatelessWidget {
  const _WeatherError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Météo indisponible pour le moment.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
