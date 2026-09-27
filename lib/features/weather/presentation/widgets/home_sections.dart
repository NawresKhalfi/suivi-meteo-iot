import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/french_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/pulsing_pin.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../core/widgets/weather_icon.dart';
import '../../../air_quality/application/air_quality_controller.dart';
import '../../../air_quality/domain/air_quality_snapshot.dart';
import '../../../air_quality/presentation/widgets/air_quality_sheet.dart';
import '../../../astronomy/presentation/widgets/astronomy_sheet.dart';
import '../../../forecast/domain/daily_forecast.dart';
import '../../../forecast/domain/hourly_forecast.dart';
import '../../../settings/application/settings_controller.dart';
import '../../domain/forecast_bundle.dart';
import '../../domain/weather_condition.dart';
import '../../domain/weather_snapshot.dart';

/// Défilement horizontal des 12 prochaines heures.
class HourlyStrip extends ConsumerWidget {
  const HourlyStrip({required this.hours, super.key});

  final List<HourlyForecast> hours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(unitFormatterProvider);
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
        itemCount: hours.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final hour = hours[i];
          final now = i == 0;
          final color = now ? Colors.white : AppColors.ink;
          return Container(
            width: 64,
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
            decoration: BoxDecoration(
              color: now ? null : AppColors.surface,
              gradient: now
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary1, AppColors.primary2],
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  now ? 'Maint.' : format.hour(hour.time),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                WeatherIcon(hour.condition.icon(isDay: hour.isDay), size: 26),
                Text(
                  format.temperature(hour.temperature),
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Grille « Aperçu détaillé » : air, UV, vent, soleil.
class DetailGrid extends ConsumerWidget {
  const DetailGrid({required this.bundle, super.key});

  final ForecastBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(unitFormatterProvider);
    final current = bundle.current;
    final air = ref.watch(airQualityProvider);
    final today = bundle.today;

    final airCard = _MiniCard(
      icon: Icons.air_rounded,
      colors: (AppColors.airGood, const Color(0xFF22B36A)),
      label: "Qualité de l'air",
      value: air.when(
        data: (a) => '${a.aqi} · ${a.level.label}',
        loading: () => '…',
        error: (_, _) => 'Indisponible',
      ),
      sub: air.valueOrNull?.pollutant('PM2.5') == null
          ? 'Toucher pour le détail'
          : 'PM2.5 ${air.valueOrNull!.pollutant('PM2.5')!.value.round()} µg/m³',
      onTap: () => showAirQualitySheet(context),
    );
    final uvCard = _MiniCard(
      icon: Icons.wb_sunny_rounded,
      colors: (AppColors.sun1, AppColors.sun2),
      label: 'Indice UV',
      value: '${current.uvIndex.round()} · ${uvLevelLabel(current.uvIndex)}',
      sub: uvAdvice(current.uvIndex),
      onTap: () => showToast(
        context,
        'Indice UV max aujourd’hui : ${today.uvIndex.round()} '
        '(${uvLevelLabel(today.uvIndex).toLowerCase()})',
      ),
    );
    final windCard = _MiniCard(
      icon: Icons.wind_power_rounded,
      colors: (AppColors.wind1, AppColors.wind2),
      label: 'Vent',
      value: format.windSpeed(current.windSpeed),
      sub: 'Direction ${current.windDirection}',
      onTap: () => showToast(
        context,
        'Vent du ${compassName(current.windDirectionDegrees)}, rafales à '
        '${format.windSpeed(current.windGust)}',
      ),
    );
    final sunCard = _MiniCard(
      icon: Icons.wb_twilight_rounded,
      colors: (AppColors.night1, AppColors.night2),
      label: 'Coucher du soleil',
      value: format.time(today.sunset),
      sub: 'Lever à ${format.time(today.sunrise)}',
      onTap: () => showAstronomySheet(context, bundle.astronomy),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: airCard),
            const SizedBox(width: 12),
            Expanded(child: uvCard),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: windCard),
            const SizedBox(width: 12),
            Expanded(child: sunCard),
          ],
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.colors,
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final (Color, Color) colors;
  final String label;
  final String value;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconBox(icon: icon, colors: colors),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.inkFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pression, visibilité, point de rosée, élévation, rafales (US02, US03).
class CurrentConditionsCard extends ConsumerWidget {
  const CurrentConditionsCard({required this.current, super.key});

  final WeatherSnapshot current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(unitFormatterProvider);
    final items = [
      (Icons.speed_rounded, 'Pression', format.pressure(current.pressure)),
      (
        Icons.visibility_outlined,
        'Visibilité',
        format.visibility(current.visibility),
      ),
      (
        Icons.water_drop_outlined,
        'Point de rosée',
        format.temperature(current.dewPoint),
      ),
      (Icons.air_rounded, 'Rafales', format.windSpeed(current.windGust)),
      (Icons.terrain_rounded, 'Élévation', '${current.elevation.round()} m'),
      (Icons.opacity_rounded, 'Humidité', '${current.humidity.round()} %'),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        children: [
          for (final (icon, label, value) in items)
            FractionallySizedBox(
              widthFactor: 0.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.primary1),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.inkFaint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            value,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Aperçu des 3 prochains jours avec barres d'amplitude.
class WeekPreview extends ConsumerWidget {
  const WeekPreview({required this.days, required this.onTap, super.key});

  final List<DailyForecast> days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(unitFormatterProvider);
    final lows = days.map((d) => d.minimumTemperature);
    final highs = days.map((d) => d.maximumTemperature);
    final low = lows.reduce((a, b) => a < b ? a : b);
    final high = highs.reduce((a, b) => a > b ? a : b);
    final span = (high - low).abs() < 1 ? 1.0 : high - low;
    final today = days.first.date;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        children: [
          for (final (i, day) in days.take(3).indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
              decoration: BoxDecoration(
                border: i < 2
                    ? const Border(bottom: BorderSide(color: AppColors.line))
                    : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      FrenchCalendar.relativeDay(day.date, today),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  WeatherIcon(day.condition.icon()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RangeBar(
                      start: (day.minimumTemperature - low) / span,
                      end: (day.maximumTemperature - low) / span,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 58),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          format.temperature(day.maximumTemperature),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          format.temperature(day.minimumTemperature),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Barre d'amplitude thermique (fractions 0–1 de l'échelle commune).
class RangeBar extends StatelessWidget {
  const RangeBar({required this.start, required this.end, super.key});

  final double start;
  final double end;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final left = width * start.clamp(0, 1);
        final barWidth = (width * (end - start).clamp(0.08, 1)).clamp(
          6.0,
          width - left,
        );
        return Container(
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: left),
          child: Container(
            width: barWidth,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.sun1, AppColors.sun2],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}

/// Vignette « Carte radar » menant à l'onglet Carte.
class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: 120,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.6, -1),
            end: Alignment(0.6, 1),
            colors: [Color(0xFF2E86D8), Color(0xFF63B4EE), Color(0xFFA9DFF9)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              const Positioned(top: -20, left: 20, child: _Cloud(90, 0.35)),
              const Positioned(bottom: -15, right: 30, child: _Cloud(70, 0.28)),
              const Align(
                alignment: Alignment(-0.08, -0.12),
                child: PulsingPin(),
              ),
              Positioned(
                left: 14,
                bottom: 12,
                child: Row(
                  children: const [
                    Icon(Icons.map_outlined, color: Colors.white, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'Voir la carte en direct',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud(this.size, this.opacity);

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: 0),
        ],
      ),
    ),
  );
}
