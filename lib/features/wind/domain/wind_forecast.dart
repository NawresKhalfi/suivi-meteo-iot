class WindForecast {
  const WindForecast({
    required this.date,
    required this.speed,
    required this.gust,
    required this.direction,
    required this.directionDegrees,
  });

  final DateTime date;
  final double speed;
  final double gust;
  final String direction;
  final int directionDegrees;
}
