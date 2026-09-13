import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/air_quality_controller.dart';
import '../../domain/air_quality_snapshot.dart';

class AirQualityScreen extends ConsumerWidget {
  const AirQualityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quality = ref.watch(airQualityControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("Qualité de l'air")),
      body: quality.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(airQualityControllerProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
        data: (snapshot) => RefreshIndicator(
          onRefresh: () =>
              ref.read(airQualityControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _QualitySummary(snapshot: snapshot),
              const SizedBox(height: 20),
              Text(
                'Polluants mesurés',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...snapshot.pollutants.map(
                (pollutant) => _PollutantTile(reading: pollutant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualitySummary extends StatelessWidget {
  const _QualitySummary({required this.snapshot});

  final AirQualitySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(snapshot.level);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color,
              child: Text(
                '${snapshot.aqi}',
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.city,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  snapshot.level.label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const Text('Indice de qualité de l’air (AQI)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _levelColor(AirQualityLevel level) {
    switch (level) {
      case AirQualityLevel.good:
        return Colors.green;
      case AirQualityLevel.moderate:
        return Colors.amber.shade800;
      case AirQualityLevel.unhealthy:
        return Colors.orange;
      case AirQualityLevel.veryUnhealthy:
        return Colors.deepOrange;
      case AirQualityLevel.hazardous:
        return Colors.red;
    }
  }
}

class _PollutantTile extends StatelessWidget {
  const _PollutantTile({required this.reading});

  final PollutantReading reading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.science_outlined),
        title: Text(reading.name),
        trailing: Text('${reading.value} ${reading.unit}'),
      ),
    );
  }
}
