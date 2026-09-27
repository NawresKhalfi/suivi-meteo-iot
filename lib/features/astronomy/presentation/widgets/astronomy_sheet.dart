import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../settings/application/settings_controller.dart';
import '../../domain/astronomy_snapshot.dart';

void showAstronomySheet(BuildContext context, AstronomySnapshot astronomy) {
  showAppSheet<void>(
    context,
    builder: (_) => AstronomySheet(astronomy: astronomy),
  );
}

/// Cycle jour/nuit et phase lunaire (E09 – US24, US25).
class AstronomySheet extends ConsumerWidget {
  const AstronomySheet({required this.astronomy, super.key});

  final AstronomySnapshot astronomy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(unitFormatterProvider);
    final length = astronomy.dayLength;
    return AppSheet(
      title: 'Soleil & Lune',
      children: [
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 2.4,
          child: CustomPaint(
            painter: _SunArcPainter(
              progress: astronomy.dayProgress,
              isDay: astronomy.isDaytime,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _Stat('Lever', format.time(astronomy.sunrise)),
            _Stat(
              'Durée du jour',
              '${length.inHours} h ${(length.inMinutes % 60).toString().padLeft(2, '0')}',
            ),
            _Stat('Coucher', format.time(astronomy.sunset)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.gradient(AppColors.night1, AppColors.night2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Text(
                astronomy.moonPhase.icon,
                style: const TextStyle(fontSize: 38),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phase lunaire',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xB3FFFFFF),
                      ),
                    ),
                    Text(
                      astronomy.moonPhase.label,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.inkFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _SunArcPainter extends CustomPainter {
  const _SunArcPainter({required this.progress, required this.isDay});

  final double progress;
  final bool isDay;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 8;
    final center = Offset(size.width / 2, baseline);
    final radius = math.min(size.width / 2 - 16, baseline - 8);
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()
        ..color = AppColors.line
        ..strokeWidth = 2,
    );
    final dashed = Paint()
      ..color = AppColors.inkFaint.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var a = 0.0; a < math.pi; a += 0.12) {
      canvas.drawArc(rect, math.pi + a, 0.06, false, dashed);
    }
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.sun1, AppColors.sun2],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final angle = math.pi + math.pi * progress;
    final sun = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(
      sun,
      11,
      Paint()..color = (isDay ? AppColors.sun1 : AppColors.inkFaint),
    );
    canvas.drawCircle(
      sun,
      17,
      Paint()
        ..color = (isDay ? AppColors.sun1 : AppColors.inkFaint).withValues(
          alpha: 0.25,
        ),
    );
  }

  @override
  bool shouldRepaint(_SunArcPainter old) =>
      old.progress != progress || old.isDay != isDay;
}
