import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/daily_forecast_controller.dart';
import '../../domain/daily_forecast.dart';

class RainProbabilityScreen extends ConsumerWidget {
  const RainProbabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(dailyForecastControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Probabilité de pluie')),
      body: forecast.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(dailyForecastControllerProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Tendance des précipitations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text('Touchez une barre pour afficher le pourcentage exact.'),
            const SizedBox(height: 20),
            _RainProbabilityChart(forecasts: items),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/radar?layer=rain'),
              icon: const Icon(Icons.radar),
              label: const Text('Voir le radar de pluie'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RainProbabilityChart extends StatefulWidget {
  const _RainProbabilityChart({required this.forecasts});

  final List<DailyForecast> forecasts;

  @override
  State<_RainProbabilityChart> createState() => _RainProbabilityChartState();
}

class _RainProbabilityChartState extends State<_RainProbabilityChart> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selected = widget.forecasts[_selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_dayLabel(selected.date)} : ${selected.rainProbability}%',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: widget.forecasts.asMap().entries.map((entry) {
              final index = entry.key;
              final forecast = entry.value;
              final selectedBar = index == _selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: forecast.rainProbability / 100,
                            widthFactor: 0.7,
                            alignment: Alignment.bottomCenter,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: selectedBar
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_dayLabel(forecast.date)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static String _dayLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}
