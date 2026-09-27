import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../core/widgets/weather_icon.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../weather/application/weather_controller.dart';
import '../../../weather/data/weather_repository.dart';
import '../../../weather/domain/weather_condition.dart';
import '../../application/cities_controller.dart';
import '../../domain/city.dart';
import '../widgets/city_sheets.dart';

/// « Mes villes » : ajout, sélection, ville par défaut, tri, suppression (E10).
class CitiesScreen extends ConsumerWidget {
  const CitiesScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, City city) async {
    final state = ref.read(citiesControllerProvider);
    if (state.isDefault(city)) {
      showToast(
        context,
        'Choisissez une autre ville par défaut avant de supprimer celle-ci',
      );
      return;
    }
    if (state.cities.length == 1) {
      showToast(context, 'Gardez au moins une ville');
      return;
    }
    final confirmed = await showAppSheet<bool>(
      context,
      builder: (_) => DeleteCitySheet(city: city),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(citiesControllerProvider.notifier).removeCity(city);
    if (context.mounted) showToast(context, '${city.name} a été supprimée');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(citiesControllerProvider);
    final weather = ref.watch(citiesWeatherProvider).valueOrNull ?? const {};
    final controller = ref.read(citiesControllerProvider.notifier);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                  title: 'Mes villes',
                  subtitle: 'Gérez vos villes suivies',
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => ref.refresh(citiesWeatherProvider.future),
                    child: ReorderableListView.builder(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 90),
                      buildDefaultDragHandles: false,
                      itemCount: state.cities.length,
                      onReorder: controller.reorder,
                      proxyDecorator: (child, _, _) => Material(
                        color: Colors.transparent,
                        elevation: 6,
                        borderRadius: BorderRadius.circular(18),
                        child: child,
                      ),
                      itemBuilder: (context, i) {
                        final city = state.cities[i];
                        return _CityRow(
                          key: ValueKey(city.id),
                          index: i,
                          city: city,
                          weather: weather[city.id],
                          isDefault: state.isDefault(city),
                          isSelected: city.id == state.selectedCityId,
                          onTap: () {
                            controller.select(city);
                            context.go(AppRoutes.home);
                          },
                          onSetDefault: () async {
                            await controller.setDefault(city);
                            if (context.mounted) {
                              showToast(
                                context,
                                '${city.name} est votre ville par défaut',
                              );
                            }
                          },
                          onDelete: () => _delete(context, ref, city),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 26,
            bottom: bottom + 20,
            child: _Fab(
              onTap: () => showAppSheet<void>(
                context,
                builder: (_) => const AddCitySheet(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityRow extends ConsumerWidget {
  const _CityRow({
    required this.index,
    required this.city,
    required this.weather,
    required this.isDefault,
    required this.isSelected,
    required this.onTap,
    required this.onSetDefault,
    required this.onDelete,
    super.key,
  });

  final int index;
  final City city;
  final CityCurrentWeather? weather;
  final bool isDefault;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(unitFormatterProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: AppColors.inkFaint,
                  size: 20,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          city.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: isSelected
                                ? AppColors.primary1
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      if (isDefault) ...[const SizedBox(width: 6), starIcon],
                    ],
                  ),
                  Text(
                    city.subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            if (weather != null)
              WeatherIcon(
                weather!.condition.icon(isDay: weather!.isDay),
                size: 26,
              ),
            SizedBox(
              width: 44,
              child: Text(
                weather == null
                    ? '–'
                    : format.temperature(weather!.temperature),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SmallButton(
              tooltip: isDefault ? 'Ville par défaut' : 'Définir par défaut',
              icon: isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isDefault ? AppColors.sun1 : AppColors.inkSoft,
              onTap: onSetDefault,
            ),
            const SizedBox(width: 6),
            _SmallButton(
              tooltip: 'Supprimer',
              icon: Icons.delete_outline_rounded,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color = AppColors.inkSoft,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.square(
            dimension: 32,
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ajouter une ville',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.shadowLg,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: const SizedBox.square(
              dimension: 54,
              child: Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
