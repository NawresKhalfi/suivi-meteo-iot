import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/french_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/application/settings_controller.dart';
import '../../domain/daily_forecast.dart';

/// Graphiques pluie (E05 – US16, US17) et vent (E06 – US18) sur 10 jours.
class RainWindPanel extends StatelessWidget {
  const RainWindPanel({
    required this.days,
    required this.onOpenRadar,
    super.key,
  });

  final List<DailyForecast> days;
  final VoidCallback onOpenRadar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChartCard(
          icon: Icons.water_drop_outlined,
          iconColor: AppColors.rain2,
          title: 'Probabilité de pluie — 10 jours',
          action: TextButton.icon(
            onPressed: onOpenRadar,
            icon: const Icon(Icons.radar_rounded, size: 16),
            label: const Text('Radar'),
          ),
          child: _RainBars(days: days),
        ),
        _ChartCard(
          icon: Icons.air_rounded,
          iconColor: AppColors.wind2,
          title: 'Vitesse et direction du vent — 10 jours',
          child: _WindChart(days: days),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Lecture de la valeur touchée (sinon le maximum).
class _Readout extends StatelessWidget {
  const _Readout({required this.day, required this.value});

  final String day;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$day  ',
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 12.5),
      ),
    );
  }
}

int _indexAt(double dx, double width, int count) =>
    (dx / width * count).floor().clamp(0, count - 1);

String _dayLabel(DailyForecast day, DateTime today) {
  final relative = FrenchCalendar.relativeDay(day.date, today);
  return relative == "Aujourd'hui"
      ? 'Auj.'
      : relative == 'Demain'
      ? 'Dem.'
      : relative;
}

class _RainBars extends StatefulWidget {
  const _RainBars({required this.days});

  final List<DailyForecast> days;

  @override
  State<_RainBars> createState() => _RainBarsState();
}

class _RainBarsState extends State<_RainBars> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    var maxIndex = 0;
    for (var i = 1; i < days.length; i++) {
      if (days[i].rainProbability > days[maxIndex].rainProbability) {
        maxIndex = i;
      }
    }
    final selected = _selected ?? maxIndex;
    final today = days.first.date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Readout(
          day:
              '${FrenchCalendar.relativeDay(days[selected].date, today)} ${FrenchCalendar.dayMonth(days[selected].date)}',
          value: '${days[selected].rainProbability}% de risque de pluie',
        ),
        LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            onTapDown: (d) => setState(
              () => _selected = _indexAt(
                d.localPosition.dx,
                constraints.maxWidth,
                days.length,
              ),
            ),
            onHorizontalDragUpdate: (d) => setState(
              () => _selected = _indexAt(
                d.localPosition.dx,
                constraints.maxWidth,
                days.length,
              ),
            ),
            child: SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, day) in days.indexed)
                    Expanded(
                      child: Semantics(
                        label:
                            '${day.rainProbability}% le ${FrenchCalendar.dayMonth(day.date)}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            height: math.max(
                              4,
                              day.rainProbability / 100 * 100,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: i == selected
                                    ? const [AppColors.rain1, AppColors.rain2]
                                    : [
                                        AppColors.rain1.withValues(alpha: 0.55),
                                        AppColors.rain2.withValues(alpha: 0.55),
                                      ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.line),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final day in days)
              Expanded(
                child: Text(
                  _dayLabel(day, today),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.inkFaint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WindChart extends ConsumerStatefulWidget {
  const _WindChart({required this.days});

  final List<DailyForecast> days;

  @override
  ConsumerState<_WindChart> createState() => _WindChartState();
}

class _WindChartState extends ConsumerState<_WindChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final format = ref.watch(unitFormatterProvider);
    final days = widget.days;
    var maxIndex = 0;
    for (var i = 1; i < days.length; i++) {
      if (days[i].windSpeed > days[maxIndex].windSpeed) maxIndex = i;
    }
    final selected = _selected ?? maxIndex;
    final day = days[selected];
    final today = days.first.date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Readout(
          day:
              '${FrenchCalendar.relativeDay(day.date, today)} ${FrenchCalendar.dayMonth(day.date)}',
          value:
              '${format.windSpeed(day.windSpeed)} ${day.windDirection} · '
              'rafales ${format.windSpeed(day.windGust)}',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            void pick(Offset p) => setState(
              () =>
                  _selected = _indexAt(p.dx, constraints.maxWidth, days.length),
            );
            return GestureDetector(
              onTapDown: (d) => pick(d.localPosition),
              onHorizontalDragUpdate: (d) => pick(d.localPosition),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WindPainter(
                    speeds: [for (final d in days) d.windSpeed],
                    selected: selected,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final d in days)
              Expanded(
                child: Column(
                  children: [
                    // La flèche indique où va le vent (direction d'origine + 180°).
                    Transform.rotate(
                      angle: (d.windDirectionDegrees + 180) * math.pi / 180,
                      child: const Icon(
                        Icons.navigation_rounded,
                        size: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    Text(
                      d.windDirection,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.inkFaint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _dayLabel(d, today),
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WindPainter extends CustomPainter {
  const _WindPainter({required this.speeds, required this.selected});

  final List<double> speeds;
  final int selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (speeds.isEmpty) return;
    const pad = 10.0;
    final top = speeds.reduce(math.max) * 1.15;
    final maxValue = top <= 0 ? 1.0 : top;
    final step = size.width / speeds.length;
    final points = [
      for (var i = 0; i < speeds.length; i++)
        Offset(
          step * (i + 0.5),
          size.height - pad - speeds[i] / maxValue * (size.height - 2 * pad),
        ),
    ];

    // Grille discrète (base).
    canvas.drawLine(
      Offset(0, size.height - pad),
      Offset(size.width, size.height - pad),
      Paint()
        ..color = AppColors.line
        ..strokeWidth = 1,
    );

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final midX = (prev.dx + cur.dx) / 2;
      line.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, size.height - pad)
      ..lineTo(points.first.dx, size.height - pad)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.wind1.withValues(alpha: 0.22),
            AppColors.wind1.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.wind1
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final sel = points[selected];
    canvas.drawLine(
      Offset(sel.dx, 0),
      Offset(sel.dx, size.height - pad),
      Paint()
        ..color = AppColors.inkFaint.withValues(alpha: 0.4)
        ..strokeWidth = 1,
    );
    for (var i = 0; i < points.length; i++) {
      final radius = i == selected ? 5.5 : 4.0;
      canvas.drawCircle(
        points[i],
        radius + 2,
        Paint()..color = AppColors.surface,
      );
      canvas.drawCircle(points[i], radius, Paint()..color = AppColors.wind1);
    }
  }

  @override
  bool shouldRepaint(_WindPainter old) =>
      old.selected != selected || old.speeds != speeds;
}
