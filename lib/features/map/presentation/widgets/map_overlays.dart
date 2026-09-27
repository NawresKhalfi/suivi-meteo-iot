import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/domain/unit_formatter.dart';
import '../../domain/map_models.dart';

/// Couleur d'une température (°C) : bleu froid → orange chaud.
Color temperatureColor(double celsius) {
  const stops = [
    (-10.0, Color(0xFF3D5AFE)),
    (0.0, Color(0xFF2FA7E0)),
    (12.0, Color(0xFF17C6A6)),
    (22.0, Color(0xFFFFB238)),
    (32.0, Color(0xFFFF7A45)),
    (40.0, Color(0xFFC81E3A)),
  ];
  if (celsius <= stops.first.$1) return stops.first.$2;
  for (var i = 1; i < stops.length; i++) {
    if (celsius <= stops[i].$1) {
      final t = (celsius - stops[i - 1].$1) / (stops[i].$1 - stops[i - 1].$1);
      return Color.lerp(stops[i - 1].$2, stops[i].$2, t)!;
    }
  }
  return stops.last.$2;
}

/// Pastille de valeur d'un point de grille selon la couche.
class GridValueMarker extends StatelessWidget {
  const GridValueMarker({
    required this.layer,
    required this.hour,
    required this.format,
    super.key,
  });

  final MapLayer layer;
  final GridHour hour;
  final UnitFormatter format;

  @override
  Widget build(BuildContext context) {
    final (Widget? icon, String text, Color color) = switch (layer) {
      MapLayer.wind => (
        Transform.rotate(
          angle: (hour.windDirection + 180) * math.pi / 180,
          child: const Icon(
            Icons.navigation_rounded,
            size: 12,
            color: Colors.white,
          ),
        ),
        format.windSpeed(hour.windSpeed).split(' ').first,
        Color.lerp(
          AppColors.wind1,
          AppColors.alert2,
          (hour.windSpeed / 60).clamp(0, 1),
        )!,
      ),
      MapLayer.clouds => (
        const Icon(Icons.cloud_rounded, size: 12, color: Colors.white),
        '${hour.cloudCover}%',
        Color.lerp(
          AppColors.primary2,
          const Color(0xFF5E7690),
          hour.cloudCover / 100,
        )!,
      ),
      _ => (
        null,
        format.temperature(hour.temperature),
        temperatureColor(hour.temperature),
      ),
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: AppColors.shadowSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 3)],
            Text(
              text,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panneau bas : horodatage, lecture/pause et points de progression.
class RadarPanel extends StatelessWidget {
  const RadarPanel({
    required this.label,
    required this.frameCount,
    required this.currentIndex,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onSelectFrame,
    this.caption,
    super.key,
  });

  final String label;
  final String? caption;
  final int frameCount;
  final int currentIndex;
  final bool isPlaying;
  final VoidCallback? onTogglePlay;
  final ValueChanged<int> onSelectFrame;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xEBFFFFFF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    if (caption != null)
                      Text(
                        caption!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.inkFaint,
                        ),
                      ),
                  ],
                ),
              ),
              Material(
                color: onTogglePlay == null
                    ? AppColors.line
                    : AppColors.primary1,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTogglePlay,
                  child: SizedBox.square(
                    dimension: 36,
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      semanticLabel: isPlaying
                          ? 'Mettre en pause'
                          : 'Lire l’animation',
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (frameCount > 1) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < frameCount; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelectFrame(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 6,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= currentIndex
                                ? AppColors.primary1
                                : AppColors.line,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
