import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/weather_icon.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../weather/domain/weather_condition.dart';
import '../../domain/hourly_forecast.dart';

/// Liste heure par heure sur 24 h (E03 – US10 à US12).
class HourlyPanel extends ConsumerWidget {
  const HourlyPanel({required this.hours, super.key});

  final List<HourlyForecast> hours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(unitFormatterProvider);
    return Column(
      children: [
        for (final (i, hour) in hours.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowSm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    i == 0 ? 'Maint.' : format.hour(hour.time),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                WeatherIcon(hour.condition.icon(isDay: hour.isDay), size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hour.condition.label(isDay: hour.isDay),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${format.windSpeed(hour.windSpeed)} ${hour.windDirection}'
                        ' · rafales ${format.windSpeed(hour.windGust)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 58, child: PrecipitationChip(hour: hour)),
                SizedBox(
                  width: 40,
                  child: Text(
                    format.temperature(hour.temperature),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Probabilité de précipitation avec son type (pluie, neige, verglas).
class PrecipitationChip extends StatelessWidget {
  const PrecipitationChip({required this.hour, super.key});

  final HourlyForecast hour;

  @override
  Widget build(BuildContext context) {
    if (hour.precipitationProbability <= 0) return const SizedBox.shrink();
    final (icon, tooltip) = switch (hour.precipitationType) {
      PrecipitationType.snow => (Icons.ac_unit_rounded, 'Neige'),
      PrecipitationType.ice => (Icons.severe_cold_rounded, 'Verglas'),
      _ => (Icons.water_drop_rounded, 'Pluie'),
    };
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.rain2),
          const SizedBox(width: 2),
          Text(
            '${hour.precipitationProbability}%',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.rain2,
            ),
          ),
        ],
      ),
    );
  }
}
