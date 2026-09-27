import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common.dart';
import '../../../cities/application/cities_controller.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/alerts_controller.dart';
import '../../domain/weather_alert.dart';
import '../widgets/alert_widgets.dart';

/// Liste des alertes en cours, à venir et historique 48 h (E02).
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsControllerProvider);
    final city = ref.watch(selectedCityProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            PageHeader(
              title: 'Alertes météo',
              subtitle: '${city.name} · prochaines 48 heures',
              leading: IconButton(
                tooltip: 'Retour',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            if (!alerts.hasAlerts)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: AppCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppColors.airGood,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aucune alerte en cours. Aucun phénomène dangereux n’est prévu '
                          'dans les prochaines 48 heures.',
                          style: TextStyle(
                            color: AppColors.inkSoft,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _Section(title: 'En cours', alerts: alerts.active),
            _Section(title: 'À venir', alerts: alerts.upcoming),
            _Section(
              title: 'Historique (48 h)',
              alerts: alerts.history,
              faded: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({
    required this.title,
    required this.alerts,
    this.faded = false,
  });

  final String title;
  final List<WeatherAlert> alerts;
  final bool faded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final format = ref.watch(unitFormatterProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(title),
          for (final alert in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Opacity(
                opacity: faded ? 0.7 : 1,
                child: AppCard(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  onTap: () => showAlertSheet(context, alert),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 44,
                        decoration: BoxDecoration(
                          color: severityColors(alert.severity).$1,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${alert.severity.label} · ${format.date(alert.startsAt)} '
                              '${format.time(alert.startsAt)} → ${format.time(alert.endsAt)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.inkFaint,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
