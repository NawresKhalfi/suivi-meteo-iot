/// Noms français des jours et des mois, sans dépendance à `intl`.
abstract final class FrenchCalendar {
  static const _weekdaysShort = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];
  static const _monthsShort = [
    'janv',
    'févr',
    'mars',
    'avr',
    'mai',
    'juin',
    'juil',
    'août',
    'sept',
    'oct',
    'nov',
    'déc',
  ];

  static String weekdayShort(DateTime date) => _weekdaysShort[date.weekday - 1];

  /// « 15 sept »
  static String dayMonth(DateTime date) =>
      '${date.day} ${_monthsShort[date.month - 1]}';

  /// « Aujourd'hui », « Demain » ou l'abréviation du jour.
  static String relativeDay(DateTime date, DateTime today) {
    final day = DateTime(date.year, date.month, date.day);
    final reference = DateTime(today.year, today.month, today.day);
    final difference = day.difference(reference).inDays;
    if (difference == 0) return "Aujourd'hui";
    if (difference == 1) return 'Demain';
    return weekdayShort(date);
  }
}

/// Direction cardinale (8 points, notation française) pour un angle en degrés.
String compassLabel(num degrees) {
  const labels = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
  final normalized = degrees % 360;
  return labels[((normalized + 22.5) ~/ 45) % 8];
}

/// Direction en toutes lettres : « Nord-Ouest ».
String compassName(num degrees) {
  const names = [
    'Nord',
    'Nord-Est',
    'Est',
    'Sud-Est',
    'Sud',
    'Sud-Ouest',
    'Ouest',
    'Nord-Ouest',
  ];
  final normalized = degrees % 360;
  return names[((normalized + 22.5) ~/ 45) % 8];
}
