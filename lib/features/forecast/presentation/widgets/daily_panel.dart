import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/french_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/weather_icon.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../weather/domain/weather_condition.dart';
import '../../domain/daily_forecast.dart';

/// Prévisions sur 10 jours en accordéon (E04 – US13 à US15).
class DailyPanel extends StatefulWidget {
  const DailyPanel({required this.days, super.key});

  final List<DailyForecast> days;

  @override
  State<DailyPanel> createState() => _DailyPanelState();
}

class _DailyPanelState extends State<DailyPanel> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    final today = widget.days.first.date;
    return Column(
      children: [
        for (final (i, day) in widget.days.indexed)
          _DayCard(
            day: day,
            label: FrenchCalendar.relativeDay(day.date, today),
            open: _open == i,
            onTap: () => setState(() => _open = _open == i ? null : i),
          ),
      ],
    );
  }
}

class _DayCard extends ConsumerWidget {
  const _DayCard({
    required this.day,
    required this.label,
    required this.open,
    required this.onTap,
  });

  final DailyForecast day;
  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(unitFormatterProvider);
    final stats = [
      ('Pluie', '${day.rainProbability}%'),
      ('Neige', '${day.snowProbability}%'),
      ('Verglas', '${day.iceProbability}%'),
      ('Foudre', '${day.lightningProbability}%'),
      ('Humidité', '${day.humidity}%'),
      ('Cumul', format.precipitation(day.precipitationSum)),
      ('Vent', format.windSpeed(day.windSpeed)),
      ('Direction', day.windDirection),
      ('Indice UV', '${day.uvIndex.round()}'),
      ('Lever', format.time(day.sunrise)),
      ('Coucher', format.time(day.sunset)),
      ('Rafales', format.windSpeed(day.windGust)),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            FrenchCalendar.dayMonth(day.date),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    WeatherIcon(day.condition.icon(), size: 26),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        day.rainProbability > 0
                            ? '${day.rainProbability}%'
                            : '',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.rain2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            format.temperature(day.maximumTemperature),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            format.temperature(day.minimumTemperature),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13.5,
                              color: AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: open
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                      child: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.9,
                        children: [
                          for (final (label, value) in stats)
                            _DayStat(label, value),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayStat extends StatelessWidget {
  const _DayStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.inkFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
