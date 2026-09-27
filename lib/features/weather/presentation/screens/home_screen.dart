import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/common.dart';
import '../../../air_quality/application/air_quality_controller.dart';
import '../../../alerts/application/alerts_controller.dart';
import '../../../alerts/presentation/widgets/alert_widgets.dart';
import '../../../cities/application/cities_controller.dart';
import '../../../cities/presentation/widgets/city_sheets.dart';
import '../../../forecast/application/forecast_tab_controller.dart';
import '../../application/weather_controller.dart';
import '../../domain/forecast_bundle.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_sections.dart';

/// Accueil : météo locale en temps réel (E01).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherControllerProvider);
    final cityName = ref.watch(selectedCityProvider).name;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: weather.when(
        data: (bundle) => _HomeContent(bundle: bundle),
        loading: () => _HomeLoading(cityName: cityName),
        error: (_, _) => ErrorRetry(
          message:
              'Météo indisponible pour $cityName.\n'
              'Vérifiez votre connexion internet.',
          onRetry: () => ref.invalidate(weatherControllerProvider),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.bundle});

  final ForecastBundle bundle;

  void _openForecast(BuildContext context, WidgetRef ref, ForecastTab tab) {
    ref.read(forecastTabProvider.notifier).select(tab);
    context.go(AppRoutes.forecast);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsControllerProvider);
    final topAlert = alerts.active.firstOrNull;
    final bottom = MediaQuery.paddingOf(context).bottom;

    final sections = <Widget>[
      if (topAlert != null)
        StaggerIn(
          delayMs: 50,
          child: AlertBanner(
            alert: topAlert,
            onTap: () => showAlertSheet(context, topAlert),
          ),
        ),
      StaggerIn(
        delayMs: 100,
        child: SectionTitle(
          "Aujourd'hui",
          actionLabel: 'Voir tout',
          onAction: () => _openForecast(context, ref, ForecastTab.hours24),
        ),
      ),
      StaggerIn(
        delayMs: 120,
        child: HourlyStrip(hours: bundle.next24Hours.take(12).toList()),
      ),
      const StaggerIn(delayMs: 160, child: SectionTitle('Aperçu détaillé')),
      StaggerIn(delayMs: 180, child: DetailGrid(bundle: bundle)),
      StaggerIn(
        delayMs: 220,
        child: SectionTitle(
          'Cette semaine',
          actionLabel: '10 jours',
          onAction: () => _openForecast(context, ref, ForecastTab.days10),
        ),
      ),
      StaggerIn(
        delayMs: 240,
        child: WeekPreview(
          days: bundle.daily,
          onTap: () => _openForecast(context, ref, ForecastTab.days10),
        ),
      ),
      const StaggerIn(
        delayMs: 260,
        child: SectionTitle('Conditions actuelles'),
      ),
      StaggerIn(
        delayMs: 270,
        child: CurrentConditionsCard(current: bundle.current),
      ),
      const StaggerIn(delayMs: 280, child: SectionTitle('Carte radar')),
      StaggerIn(
        delayMs: 300,
        child: MapPreviewCard(onTap: () => context.go(AppRoutes.map)),
      ),
    ];

    return RefreshIndicator(
      color: AppColors.primary1,
      onRefresh: () async {
        ref.invalidate(airQualityProvider);
        await ref.read(weatherControllerProvider.notifier).refresh();
      },
      child: ListView(
        padding: EdgeInsets.only(bottom: bottom + 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          HomeHero(
            bundle: bundle,
            hasAlerts: alerts.hasAlerts,
            onCityTap: () => showAppSheet<void>(
              context,
              builder: (_) => const CitySwitchSheet(),
            ),
            onBellTap: () {
              final alert = alerts.mostSevere;
              if (alert != null) {
                showAlertSheet(context, alert);
              } else {
                context.push(AppRoutes.alerts);
              }
            },
          ),
          // Le bandeau d'alerte chevauche le bas du bandeau (prototype).
          Transform.translate(
            offset: Offset(0, topAlert != null ? -22 : 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: sections,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading({required this.cityName});

  final String cityName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Chargement de la météo de $cityName…',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
