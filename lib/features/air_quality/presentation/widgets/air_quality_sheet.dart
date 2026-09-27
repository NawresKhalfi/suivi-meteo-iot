import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../application/air_quality_controller.dart';
import '../../domain/air_quality_snapshot.dart';

Color airQualityColor(AirQualityLevel level) => switch (level) {
  AirQualityLevel.good => AppColors.airGood,
  AirQualityLevel.moderate => AppColors.airModerate,
  AirQualityLevel.unhealthySensitive => AppColors.airPoor,
  _ => AppColors.airBad,
};

Color pollutantColor(double ratio) {
  if (ratio <= 1) return AppColors.airGood;
  if (ratio <= 2) return AppColors.airModerate;
  if (ratio <= 3) return AppColors.airPoor;
  return AppColors.airBad;
}

void showAirQualitySheet(BuildContext context) {
  showAppSheet<void>(context, builder: (_) => const AirQualitySheet());
}

/// Qualité de l'air : indice global + six polluants (E07 – US19, US20).
class AirQualitySheet extends ConsumerWidget {
  const AirQualitySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final air = ref.watch(airQualityProvider);
    return AppSheet(
      title: "Qualité de l'air — ${air.valueOrNull?.city ?? ''}",
      children: [
        air.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              "Données de qualité de l'air indisponibles pour le moment.",
              style: TextStyle(color: AppColors.inkSoft),
            ),
          ),
          data: (snapshot) => _AirQualityContent(snapshot: snapshot),
        ),
      ],
    );
  }
}

class _AirQualityContent extends StatelessWidget {
  const _AirQualityContent({required this.snapshot});

  final AirQualitySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final color = airQualityColor(snapshot.level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 86,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: math.min(snapshot.aqi / 300, 1),
                    color: color,
                  ),
                  child: Center(
                    child: Text(
                      '${snapshot.aqi}',
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        snapshot.level.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color.lerp(color, AppColors.ink, 0.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.level.advice,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (final pollutant in snapshot.pollutants)
          _PollutantRow(pollutant: pollutant),
        const SizedBox(height: 10),
        const Text(
          'Indice US AQI · jauges rapportées aux valeurs guides OMS · '
          'Source : Open-Meteo / CAMS',
          style: TextStyle(fontSize: 11, color: AppColors.inkFaint),
        ),
      ],
    );
  }
}

class _PollutantRow extends StatelessWidget {
  const _PollutantRow({required this.pollutant});

  final PollutantReading pollutant;

  @override
  Widget build(BuildContext context) {
    final value = pollutant.value < 10
        ? pollutant.value.toStringAsFixed(1).replaceAll('.', ',')
        : pollutant.value.round().toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              pollutant.name,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: math.min(pollutant.ratio / 3, 1),
                minHeight: 7,
                backgroundColor: AppColors.line,
                color: pollutantColor(pollutant.ratio),
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              '$value ${pollutant.unit}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(9 / 2 + 2);
    final base = Paint()
      ..color = const Color(0xFFE4F1FB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawArc(ring, 0, math.pi * 2, false, base);
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi * 2 * math.max(progress, 0.02),
      false,
      base
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
