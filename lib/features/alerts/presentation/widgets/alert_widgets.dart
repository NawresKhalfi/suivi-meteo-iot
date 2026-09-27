import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../settings/application/settings_controller.dart';
import '../../domain/hazard_event.dart';
import '../../domain/weather_alert.dart';

(Color, Color) severityColors(AlertSeverity severity) => switch (severity) {
  AlertSeverity.information => (AppColors.primary1, AppColors.primary3),
  AlertSeverity.vigilance => (AppColors.sun1, AppColors.sun2),
  AlertSeverity.danger => (AppColors.alert1, AppColors.alert2),
  AlertSeverity.extreme => (AppColors.alert2, const Color(0xFF7A0C22)),
};

/// Bandeau rouge d'alerte de l'accueil.
class AlertBanner extends StatelessWidget {
  const AlertBanner({required this.alert, required this.onTap, super.key});

  final WeatherAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = severityColors(alert.severity);
    return Consumer(
      builder: (context, ref, _) {
        final format = ref.watch(unitFormatterProvider);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-1, -0.4),
              end: const Alignment(1, 0.4),
              colors: [colors.$1, colors.$2],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colors.$2.withValues(alpha: 0.45),
                blurRadius: 26,
                spreadRadius: -8,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: const TextStyle(
                              fontFamily: AppFonts.display,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Jusqu’à ${format.time(alert.endsAt)} · '
                            'Toucher pour le détail',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showAlertSheet(BuildContext context, WeatherAlert alert) {
  return showAppSheet<void>(
    context,
    builder: (_) => AlertDetailSheet(alert: alert),
  );
}

/// Détail complet d'une alerte (E02 – US07).
class AlertDetailSheet extends ConsumerWidget {
  const AlertDetailSheet({required this.alert, super.key});

  final WeatherAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(unitFormatterProvider);
    String when(DateTime value) =>
        '${format.date(value)}, ${format.time(value)}';
    return AppSheet(
      showClose: true,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SeverityBadge(severity: alert.severity),
        ),
        const SizedBox(height: 12),
        Text(
          alert.title,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        _MetaRow(
          items: [
            ('Zone affectée', alert.zone),
            ('Source', alert.source == hazardSource ? 'GDACS' : 'Open-Meteo'),
          ],
        ),
        _MetaRow(
          items: [('Début', when(alert.startsAt)), ('Fin', when(alert.endsAt))],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            alert.summary,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: AppColors.inkSoft,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Critère de déclenchement : « ${alert.originalText} »\n'
            '${alert.source}. Suivez toujours les consignes des autorités '
            'locales.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 6),
        AppButton(
          label: "J'ai compris",
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Toutes les alertes',
          style: AppButtonStyle.ghost,
          onPressed: () {
            Navigator.of(context).pop();
            context.push(AppRoutes.alerts);
          },
        ),
      ],
    );
  }
}

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({required this.severity, super.key});

  final AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: severityColors(severity).$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.priority_high_rounded,
            color: Colors.white,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            severity.label,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in items)
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
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
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
