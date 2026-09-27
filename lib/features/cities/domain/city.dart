class City {
  const City({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.region,
  });

  final String name;
  final String country;
  final String? region;
  final double latitude;
  final double longitude;

  /// Identifiant stable basé sur les coordonnées (≈ 100 m de précision).
  String get id =>
      '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';

  String get subtitle =>
      region == null || region == name ? country : '$region, $country';

  Map<String, Object?> toJson() => {
    'name': name,
    'country': country,
    'region': region,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory City.fromJson(Map<String, dynamic> json) => City(
    name: json['name'] as String,
    country: json['country'] as String,
    region: json['region'] as String?,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  @override
  bool operator ==(Object other) => other is City && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Ville proposée au premier lancement.
const defaultCity = City(
  name: 'Nabeul',
  country: 'Tunisie',
  latitude: 36.4561,
  longitude: 10.7376,
);

/// Suggestions affichées avant toute recherche dans « Ajouter une ville ».
const popularCities = [
  City(
    name: 'Tunis',
    country: 'Tunisie',
    latitude: 36.8190,
    longitude: 10.1658,
  ),
  City(
    name: 'Sousse',
    country: 'Tunisie',
    latitude: 35.8254,
    longitude: 10.6370,
  ),
  City(name: 'Sfax', country: 'Tunisie', latitude: 34.7406, longitude: 10.7603),
  City(name: 'Paris', country: 'France', latitude: 48.8534, longitude: 2.3488),
  City(
    name: 'Marseille',
    country: 'France',
    latitude: 43.2965,
    longitude: 5.3698,
  ),
  City(
    name: 'Londres',
    country: 'Royaume-Uni',
    latitude: 51.5085,
    longitude: -0.1257,
  ),
  City(
    name: 'Le Caire',
    country: 'Égypte',
    latitude: 30.0626,
    longitude: 31.2497,
  ),
  City(
    name: 'Madrid',
    country: 'Espagne',
    latitude: 40.4165,
    longitude: -3.7026,
  ),
  City(
    name: 'New York',
    country: 'États-Unis',
    latitude: 40.7143,
    longitude: -74.0060,
  ),
  City(name: 'Tokyo', country: 'Japon', latitude: 35.6895, longitude: 139.6917),
];
