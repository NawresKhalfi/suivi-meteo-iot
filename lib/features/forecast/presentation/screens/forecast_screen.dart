import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/common.dart';
import '../../../cities/application/cities_controller.dart';
import '../../../map/application/map_controller.dart';
import '../../../map/domain/map_models.dart';
import '../../../weather/application/weather_controller.dart';
import '../../application/forecast_tab_controller.dart';
import '../widgets/daily_panel.dart';
import '../widgets/hourly_panel.dart';
import '../widgets/rain_wind_panel.dart';
import '../widgets/segmented_tabs.dart';

/// Onglet Prévisions : 24 heures, 10 jours, pluie & vent.
class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(forecastTabProvider);
    final city = ref.watch(selectedCityProvider);
    final weather = ref.watch(weatherControllerProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: 'Prévisions',
              subtitle: '${city.name}, ${city.country}',
            ),
            SegmentedTabs(
              labels: [for (final t in ForecastTab.values) t.label],
              selectedIndex: tab.index,
              onSelected: (i) => ref
                  .read(forecastTabProvider.notifier)
                  .select(ForecastTab.values[i]),
            ),
            Expanded(
              child: weather.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => ErrorRetry(
                  message: 'Prévisions indisponibles.',
                  onRetry: () => ref.invalidate(weatherControllerProvider),
                ),
                data: (bundle) => RefreshIndicator(
                  onRefresh: ref
                      .read(weatherControllerProvider.notifier)
                      .refresh,
                  child: ListView(
                    key: PageStorageKey(tab),
                    padding: EdgeInsets.fromLTRB(20, 6, 20, bottom + 24),
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: KeyedSubtree(
                          key: ValueKey(tab),
                          child: switch (tab) {
                            ForecastTab.hours24 => HourlyPanel(
                              hours: bundle.next24Hours,
                            ),
                            ForecastTab.days10 => DailyPanel(
                              days: bundle.daily,
                            ),
                            ForecastTab.rainWind => RainWindPanel(
                              days: bundle.daily,
                              onOpenRadar: () {
                                ref
                                    .read(mapViewControllerProvider.notifier)
                                    .selectLayer(MapLayer.precipitation);
                                context.go(AppRoutes.map);
                              },
                            ),
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
