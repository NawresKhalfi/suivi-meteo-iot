enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

class AstronomySnapshot {
  const AstronomySnapshot({
    required this.sunrise,
    required this.sunset,
    required this.moonPhase,
    required this.observedAt,
  });

  final DateTime sunrise;
  final DateTime sunset;
  final MoonPhase moonPhase;
  final DateTime observedAt;
}

extension MoonPhaseLabels on MoonPhase {
  String get label {
    switch (this) {
      case MoonPhase.newMoon:
        return 'Nouvelle lune';
      case MoonPhase.waxingCrescent:
        return 'Premier croissant';
      case MoonPhase.firstQuarter:
        return 'Premier quartier';
      case MoonPhase.waxingGibbous:
        return 'Gibbeuse croissante';
      case MoonPhase.fullMoon:
        return 'Pleine lune';
      case MoonPhase.waningGibbous:
        return 'Gibbeuse décroissante';
      case MoonPhase.lastQuarter:
        return 'Dernier quartier';
      case MoonPhase.waningCrescent:
        return 'Dernier croissant';
    }
  }

  String get icon {
    switch (this) {
      case MoonPhase.newMoon:
        return '🌑';
      case MoonPhase.waxingCrescent:
        return '🌒';
      case MoonPhase.firstQuarter:
        return '🌓';
      case MoonPhase.waxingGibbous:
        return '🌔';
      case MoonPhase.fullMoon:
        return '🌕';
      case MoonPhase.waningGibbous:
        return '🌖';
      case MoonPhase.lastQuarter:
        return '🌗';
      case MoonPhase.waningCrescent:
        return '🌘';
    }
  }
}

MoonPhase moonPhaseForDate(DateTime date) {
  final daysSinceReference =
      date.difference(DateTime.utc(2000, 1, 6)).inHours / 24;
  final cyclePosition = (daysSinceReference % 29.530588853) / 29.530588853;
  final index = (cyclePosition * MoonPhase.values.length).floor();
  return MoonPhase.values[index.clamp(0, MoonPhase.values.length - 1)];
}
