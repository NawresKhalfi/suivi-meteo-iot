import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alerts_repository.dart';
import '../domain/weather_alert.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return DemoAlertsRepository();
});

final alertNotificationServiceProvider = Provider<AlertNotificationService>((
  ref,
) {
  return UnconfiguredAlertNotificationService();
});

final alertNotificationsEnabledProvider = NotifierProvider<
  AlertNotificationsController,
  bool
>(AlertNotificationsController.new);

class AlertNotificationsController extends Notifier<bool> {
  AlertNotificationService get _service =>
      ref.read(alertNotificationServiceProvider);

  @override
  bool build() => _service.isEnabled;

  Future<void> enable() async {
    await _service.configure();
    state = true;
  }

  Future<void> disable() async {
    await _service.disable();
    state = false;
  }
}

final alertsControllerProvider =
    AsyncNotifierProvider<AlertsController, List<WeatherAlert>>(
      AlertsController.new,
    );

class AlertsController extends AsyncNotifier<List<WeatherAlert>> {
  AlertsRepository get _repository => ref.read(alertsRepositoryProvider);

  @override
  Future<List<WeatherAlert>> build() => _load();

  Future<List<WeatherAlert>> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
    return state.value ?? const [];
  }

  Future<List<WeatherAlert>> _load() async {
    final alerts = await _repository.fetchAlerts();
    alerts.sort((first, second) {
      final severity = second.severity.priority.compareTo(
        first.severity.priority,
      );
      return severity != 0
          ? severity
          : second.startsAt.compareTo(first.startsAt);
    });
    return alerts;
  }

  List<WeatherAlert> history({DateTime? now}) {
    final reference = now ?? DateTime.now();
    return state.valueOrNull
            ?.where(
              (alert) =>
                  alert.endsAt.isBefore(reference) &&
                  alert.endsAt.isAfter(
                    reference.subtract(const Duration(hours: 48)),
                  ),
            )
            .toList() ??
        const [];
  }
}
