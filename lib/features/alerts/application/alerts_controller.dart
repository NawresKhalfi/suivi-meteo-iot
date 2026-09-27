import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/http_client_provider.dart';
import '../../cities/application/cities_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../weather/application/weather_controller.dart';
import '../data/alerts_repository.dart';
import '../data/hazard_repository.dart';
import '../domain/alert_rules.dart';
import '../domain/hazard_event.dart';
import '../domain/weather_alert.dart';

final alertsHistoryStoreProvider = Provider<AlertsHistoryStore>(
  (ref) => MemoryAlertsHistoryStore(),
);

final hazardRepositoryProvider = Provider<HazardRepository>(
  (ref) => GdacsHazardRepository(ref.watch(httpClientProvider)),
);

/// Catastrophes en cours (GDACS), rechargées toutes les 30 minutes.
final hazardEventsProvider = FutureProvider<List<HazardEvent>>((ref) {
  final timer = Timer(const Duration(minutes: 30), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(hazardRepositoryProvider).fetchCurrentEvents();
});

final alertNotificationServiceProvider = Provider<AlertNotificationService>(
  (ref) => UnconfiguredAlertNotificationService(),
);

final alertNotificationsEnabledProvider =
    NotifierProvider<AlertNotificationsController, bool>(
      AlertNotificationsController.new,
    );

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

class AlertsState {
  const AlertsState({
    this.active = const [],
    this.upcoming = const [],
    this.history = const [],
  });

  final List<WeatherAlert> active;
  final List<WeatherAlert> upcoming;

  /// Alertes terminées depuis moins de 48 h.
  final List<WeatherAlert> history;

  WeatherAlert? get mostSevere => active.isNotEmpty
      ? active.first
      : upcoming.isNotEmpty
      ? upcoming.first
      : null;

  bool get hasAlerts => active.isNotEmpty || upcoming.isNotEmpty;
}

final alertsControllerProvider =
    NotifierProvider<AlertsController, AlertsState>(AlertsController.new);

class AlertsController extends Notifier<AlertsState> {
  @override
  AlertsState build() {
    final bundle = ref.watch(weatherControllerProvider).valueOrNull;
    if (bundle == null) return const AlertsState();
    final city = ref.watch(selectedCityProvider);
    final format = ref.watch(unitFormatterProvider);
    final store = ref.read(alertsHistoryStoreProvider);
    final now = bundle.current.observedAt;

    final hazards = ref.watch(hazardEventsProvider).valueOrNull ?? const [];
    final derived = [
      ...deriveAlerts(bundle, zone: city.name, format: format),
      ...hazardAlerts(hazards, city: city, now: now),
    ];
    final byId = {
      for (final alert in store.read(city.id)) alert.id: alert,
      for (final alert in derived) alert.id: alert,
    };
    final kept = byId.values
        .where((a) => a.endsAt.isAfter(now.subtract(const Duration(hours: 48))))
        .toList();
    unawaited(store.save(city.id, kept));

    List<WeatherAlert> sorted(bool Function(WeatherAlert) test) =>
        kept.where(test).toList()..sort(compareAlerts);

    return AlertsState(
      active: sorted((a) => a.isActiveAt(now)),
      upcoming: sorted((a) => a.isUpcomingAt(now)),
      history: kept.where((a) => !a.endsAt.isAfter(now)).toList()
        ..sort((a, b) => b.endsAt.compareTo(a.endsAt)),
    );
  }
}
