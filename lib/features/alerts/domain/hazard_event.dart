import 'dart:math' as math;

import '../../cities/domain/city.dart';
import 'weather_alert.dart';

const hazardSource = 'GDACS (ONU / Commission européenne)';

/// Types d'événements suivis par GDACS, avec le rayon (km) autour de la
/// ville dans lequel un événement en cours déclenche une alerte.
enum HazardType {
  wildfire('WF', 150),
  flood('FL', 250),
  earthquake('EQ', 300),
  cyclone('TC', 800),
  volcano('VO', 200),
  drought('DR', 500);

  const HazardType(this.code, this.radiusKm);

  final String code;
  final double radiusKm;

  static HazardType? fromCode(String code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

enum HazardLevel { green, orange, red }

/// Catastrophe naturelle en cours signalée par GDACS.
class HazardEvent {
  const HazardEvent({
    required this.id,
    required this.type,
    required this.level,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.from,
    required this.to,
    required this.description,
    this.severityText,
  });

  final String id;
  final HazardType type;
  final HazardLevel level;
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final DateTime from;
  final DateTime to;
  final String description;
  final String? severityText;
}

/// Transforme les événements GDACS proches de [city] en alertes.
List<WeatherAlert> hazardAlerts(
  List<HazardEvent> events, {
  required City city,
  required DateTime now,
}) {
  final alerts = <WeatherAlert>[];
  for (final event in events) {
    final distance = distanceKm(
      city.latitude,
      city.longitude,
      event.latitude,
      event.longitude,
    );
    if (distance > event.type.radiusKm) continue;
    final km = distance < 1 ? '< 1' : '${distance.round()}';
    alerts.add(
      WeatherAlert(
        id: 'gdacs-${event.type.code}-${event.id}',
        title: _title(event.type),
        summary:
            '${_advice(event.type)} Événement signalé à environ $km km '
            'de ${city.name}.',
        zone: '${city.name} et environs ($km km)',
        source: hazardSource,
        severity: switch (event.level) {
          HazardLevel.green => AlertSeverity.vigilance,
          HazardLevel.orange => AlertSeverity.danger,
          HazardLevel.red => AlertSeverity.extreme,
        },
        startsAt: event.from,
        // GDACS garde « en cours » des événements dont la dernière mise à jour
        // est passée : on les laisse actifs jusqu'au prochain rafraîchissement.
        endsAt: event.to.isAfter(now)
            ? event.to
            : now.add(const Duration(hours: 6)),
        originalText: [
          event.description,
          if (event.severityText != null) event.severityText!,
        ].join(' '),
      ),
    );
  }
  alerts.sort(compareAlerts);
  return alerts;
}

String _title(HazardType type) => switch (type) {
  HazardType.wildfire => 'Incendie de forêt à proximité',
  HazardType.flood => 'Inondation en cours',
  HazardType.earthquake => 'Séisme ressenti dans la région',
  HazardType.cyclone => 'Tempête tropicale / médicane',
  HazardType.volcano => 'Éruption volcanique',
  HazardType.drought => 'Sécheresse',
};

String _advice(HazardType type) => switch (type) {
  HazardType.wildfire =>
    'Feu actif dans la zone : éloignez-vous des fumées, ne gênez pas les '
        'secours et préparez-vous à évacuer si les autorités le demandent.',
  HazardType.flood =>
    'Évitez les zones inondables, ne traversez jamais une route submergée.',
  HazardType.earthquake =>
    'Des répliques sont possibles : éloignez-vous des bâtiments fragilisés.',
  HazardType.cyclone =>
    'Vents violents et fortes pluies possibles : restez à l’abri.',
  HazardType.volcano => 'Retombées de cendres possibles : limitez vos sorties.',
  HazardType.drought =>
    'Ressources en eau limitées : économisez l’eau, risque d’incendie accru.',
};

/// Distance orthodromique (formule de haversine), en kilomètres.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadius * math.asin(math.sqrt(a));
}
