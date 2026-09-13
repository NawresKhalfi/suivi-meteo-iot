import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/wind_forecast_controller.dart';
import '../../domain/wind_forecast.dart';

class WindForecastScreen extends ConsumerWidget {
  const WindForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wind = ref.watch(windForecastControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Vent sur 10 jours')),
      body: wind.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(windForecastControllerProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () =>
              ref.read(windForecastControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Vitesse du vent',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'Touchez un point pour voir son orientation et sa vitesse.',
              ),
              const SizedBox(height: 16),
              _WindChart(forecasts: items),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindChart extends StatefulWidget {
  const _WindChart({required this.forecasts});

  final List<WindForecast> forecasts;

  @override
  State<_WindChart> createState() => _WindChartState();
}

class _WindChartState extends State<_WindChart> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selected = widget.forecasts[_selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_dateLabel(selected.date)} : ${selected.speed.toStringAsFixed(1)} km/h ${selected.direction}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'Rafales ${selected.gust.toStringAsFixed(0)} km/h • ${selected.directionDegrees}°',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: CustomPaint(
            painter: _WindChartPainter(
              forecasts: widget.forecasts,
              selectedIndex: _selectedIndex,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final width = context.size?.width ?? 1;
                final index =
                    ((details.localPosition.dx / width) *
                            widget.forecasts.length)
                        .floor()
                        .clamp(0, widget.forecasts.length - 1);
                setState(() => _selectedIndex = index);
              },
            ),
          ),
        ),
      ],
    );
  }

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

class _WindChartPainter extends CustomPainter {
  const _WindChartPainter({
    required this.forecasts,
    required this.selectedIndex,
    required this.color,
  });

  final List<WindForecast> forecasts;
  final int selectedIndex;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final maxSpeed =
        forecasts
            .map((forecast) => forecast.speed)
            .reduce((first, second) => first > second ? first : second) +
        2;
    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final point = Paint()..color = color;
    final path = Path();
    for (var index = 0; index < forecasts.length; index++) {
      final x = size.width * index / (forecasts.length - 1);
      final y =
          size.height -
          (forecasts[index].speed / maxSpeed) * (size.height - 28);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), index == selectedIndex ? 7 : 4, point);
      final label = TextPainter(
        text: TextSpan(
          text: forecasts[index].direction,
          style: TextStyle(color: color, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(x - label.width / 2, size.height - 22));
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(_WindChartPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.forecasts != forecasts;
}
