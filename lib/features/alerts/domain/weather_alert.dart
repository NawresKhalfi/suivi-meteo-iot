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

  bool isActiveAt(DateTime now) =>
      !startsAt.isAfter(now) && endsAt.isAfter(now);

  bool isUpcomingAt(DateTime now) => startsAt.isAfter(now);

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'zone': zone,
    'source': source,
    'severity': severity.name,
    'startsAt': startsAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'originalText': originalText,
  };

  factory WeatherAlert.fromJson(Map<String, dynamic> json) => WeatherAlert(
    id: json['id'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String,
    zone: json['zone'] as String,
    source: json['source'] as String,
    severity: AlertSeverity.values.byName(json['severity'] as String),
    startsAt: DateTime.parse(json['startsAt'] as String),
    endsAt: DateTime.parse(json['endsAt'] as String),
    originalText: json['originalText'] as String,
  );
}

extension AlertSeverityLabels on AlertSeverity {
  String get label => switch (this) {
    AlertSeverity.information => 'Information',
    AlertSeverity.vigilance => 'Vigilance jaune',
    AlertSeverity.danger => 'Danger — Vigilance orange',
    AlertSeverity.extreme => 'Extrême — Vigilance rouge',
  };

  int get priority => index;
}

/// Tri : gravité décroissante, puis début le plus proche (E02 – US08).
int compareAlerts(WeatherAlert a, WeatherAlert b) {
  final severity = b.severity.priority.compareTo(a.severity.priority);
  return severity != 0 ? severity : a.startsAt.compareTo(b.startsAt);
}
