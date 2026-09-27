import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/weather_icon.dart';
import '../../../settings/application/settings_controller.dart';
import '../../domain/forecast_bundle.dart';
import '../../domain/weather_condition.dart';

/// Bandeau dégradé : ville, température, condition et indicateurs clés.
class HomeHero extends ConsumerWidget {
  const HomeHero({
    required this.bundle,
    required this.hasAlerts,
    required this.onCityTap,
    required this.onBellTap,
    super.key,
  });

  final ForecastBundle bundle;
  final bool hasAlerts;
  final VoidCallback onCityTap;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(unitFormatterProvider);
    final current = bundle.current;
    final top = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(38)),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            const Positioned(
              top: -70,
              right: -50,
              child: _Blob(180, Color(0xFF7FD8FF), 0.5),
            ),
            const Positioned(
              bottom: -60,
              left: -40,
              child: _Blob(140, AppColors.sun1, 0.35),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(22, top + 16, 22, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _CityPicker(
                            name: current.city,
                            subtitle: updatedLabel(bundle, format.time),
                            onTap: onCityTap,
                          ),
                        ),
                      ),
                      _BellButton(hasBadge: hasAlerts, onTap: onBellTap),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _BigTemperature(
                        format.convertTemperature(current.temperature),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              current.condition.description(
                                isDay: current.isDay,
                              ),
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Max ${format.temperature(bundle.today.maximumTemperature)}'
                              ' · Min ${format.temperature(bundle.today.minimumTemperature)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      HeroWeatherIcon(
                        current.condition.icon(isDay: current.isDay),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                        format.temperature(current.apparentTemperature),
                        'Ressenti',
                      ),
                      _StatChip(format.windSpeed(current.windSpeed), 'Vent'),
                      _StatChip('${current.humidity.round()}%', 'Humidité'),
                      _StatChip('${current.uvIndex.round()}', 'Indice UV'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Mis à jour à l'instant », « il y a 12 min » ou « Hors ligne ».
String updatedLabel(ForecastBundle bundle, String Function(DateTime) time) {
  final updatedAt = bundle.current.updatedAt;
  if (bundle.current.isOffline) {
    return 'Hors ligne · données de ${time(updatedAt)}';
  }
  final minutes = DateTime.now().difference(updatedAt).inMinutes;
  if (minutes < 2) return "Mis à jour à l'instant";
  if (minutes < 60) return 'Mis à jour il y a $minutes min';
  return 'Mis à jour à ${time(updatedAt)}';
}

class _Blob extends StatelessWidget {
  const _Blob(this.size, this.color, this.opacity);

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 0.7],
        ),
      ),
    ),
  );
}

class _CityPicker extends StatelessWidget {
  const _CityPicker({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xBFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasBadge, required this.onTap});

  final bool hasBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Alertes météo',
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox.square(
            dimension: 38,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                if (hasBadge)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.alert1,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary1, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BigTemperature extends StatelessWidget {
  const _BigTemperature(this.value);

  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${value.round()}',
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w800,
            fontSize: 76,
            height: 1,
            letterSpacing: -2,
            color: Colors.white,
          ),
        ),
        const Text(
          '°',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w600,
            fontSize: 34,
            height: 1,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xBFFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
