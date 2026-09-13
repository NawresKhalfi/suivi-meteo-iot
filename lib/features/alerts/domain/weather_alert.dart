enum AlertSeverity { information, vigilance, danger, extreme }

class WeatherAlert {
  const WeatherAlert({
    required this.id,
    required this.title,
    required this.summary,
    required this.zone,
    required this.source,
    required this.severity,
    required this.startsAt,
    required this.endsAt,
    required this.originalText,
  });

  final String id;
  final String title;
  final String summary;
  final String zone;
  final String source;
  final AlertSeverity severity;
  final DateTime startsAt;
  final DateTime endsAt;
  final String originalText;

  bool isActiveAt(DateTime now) {
    return !startsAt.isAfter(now) && endsAt.isAfter(now);
  }
}

extension AlertSeverityLabels on AlertSeverity {
  String get label {
    switch (this) {
      case AlertSeverity.information:
        return 'Information';
      case AlertSeverity.vigilance:
        return 'Vigilance';
      case AlertSeverity.danger:
        return 'Danger';
      case AlertSeverity.extreme:
        return 'Extrême';
    }
  }

  int get priority => index;
}
