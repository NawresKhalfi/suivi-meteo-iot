import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/alerts_controller.dart';
import '../../domain/weather_alert.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes météo')),
      body: alerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(alertsControllerProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
        data: (items) {
          final now = DateTime.now();
          final activeAlerts = items.where((alert) => alert.isActiveAt(now));
          final history = ref
              .read(alertsControllerProvider.notifier)
              .history(now: now);
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(alertsControllerProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const _NotificationOptInCard(),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Alertes en cours',
                  subtitle: '${activeAlerts.length} alerte(s) active(s)',
                ),
                const SizedBox(height: 8),
                ...activeAlerts.map((alert) => _AlertTile(alert: alert)),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Historique des 48 dernières heures',
                  subtitle: 'Les événements récents restent consultables ici',
                ),
                const SizedBox(height: 8),
                ...history.map((alert) => _AlertTile(alert: alert)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationOptInCard extends ConsumerWidget {
  const _NotificationOptInCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(alertNotificationsEnabledProvider);
    final controller = ref.read(
      alertNotificationsEnabledProvider.notifier,
    );
    return Card(
      child: SwitchListTile.adaptive(
        value: enabled,
        onChanged: (value) async {
          if (value) {
            await controller.enable();
          } else {
            await controller.disable();
          }
        },
        secondary: Icon(
          enabled ? Icons.notifications_active : Icons.notifications_off,
        ),
        title: const Text('Alertes push de ma zone'),
        subtitle: Text(
          enabled
              ? 'Vous recevrez les nouvelles alertes importantes.'
              : 'Activez-les uniquement si vous souhaitez être prévenu.',
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final WeatherAlert alert;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _severityColor(alert.severity),
          child: const Icon(Icons.warning_amber, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.title),
            Chip(
              label: Text(alert.severity.label),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        subtitle: Text(alert.summary),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AlertDetailScreen(alert: alert),
          ),
        ),
      ),
    );
  }

  static Color _severityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.information:
        return Colors.blueGrey;
      case AlertSeverity.vigilance:
        return Colors.orange;
      case AlertSeverity.danger:
        return Colors.deepOrange;
      case AlertSeverity.extreme:
        return Colors.red;
    }
  }
}

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({required this.alert, super.key});

  final WeatherAlert alert;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(alert.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Chip(label: Text(alert.severity.label)),
          const SizedBox(height: 16),
          _DetailRow(label: 'Zone', value: alert.zone),
          _DetailRow(label: 'Début', value: _format(alert.startsAt)),
          _DetailRow(label: 'Fin', value: _format(alert.endsAt)),
          _DetailRow(label: 'Résumé', value: alert.summary),
          _DetailRow(label: 'Source', value: alert.source),
          const SizedBox(height: 16),
          Text(
            'Texte officiel',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(alert.originalText),
        ],
      ),
    );
  }

  static String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(value),
        ],
      ),
    );
  }
}
