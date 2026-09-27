enum MapLayer {
  temperature('Température'),
  precipitation('Précipitations'),
  wind('Vent'),
  clouds('Nuages');

  const MapLayer(this.label);
  final String label;
}

/// Image radar RainViewer (passé ou prévision immédiate).
class RadarFrame {
  const RadarFrame({
    required this.time,
    required this.path,
    this.isForecast = false,
  });

  /// Instant UTC de l'image.
  final DateTime time;
  final String path;
  final bool isForecast;
}

class RadarFrames {
  const RadarFrames({required this.host, required this.frames});

  final String host;
  final List<RadarFrame> frames;

  String tileUrl(RadarFrame frame) =>
      '$host${frame.path}/256/{z}/{x}/{y}/2/1_1.png';

  /// Index de l'image la plus récente déjà observée (« Maintenant »).
  int get nowIndex {
    final index = frames.lastIndexWhere((frame) => !frame.isForecast);
    return index < 0 ? 0 : index;
  }
}

class GridHour {
  const GridHour({
    required this.time,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.cloudCover,
  });

  final DateTime time;
  final double temperature;
  final double windSpeed;
  final int windDirection;
  final int cloudCover;
}

/// Point de la grille météo affichée sur la carte.
class GridPoint {
  const GridPoint({
    required this.latitude,
    required this.longitude,
    required this.hours,
  });

  final double latitude;
  final double longitude;
  final List<GridHour> hours;
}
