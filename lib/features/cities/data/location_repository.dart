import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../domain/city.dart';

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class LocationRepository {
  /// Demande l'autorisation, lit la position et la transforme en ville.
  Future<City> currentCity();
}

/// Position de l'appareil (geolocator) + nom du lieu via Nominatim
/// (OpenStreetMap, gratuit, sans clé).
class DeviceLocationRepository implements LocationRepository {
  DeviceLocationRepository(this._client);

  final http.Client _client;

  @override
  Future<City> currentCity() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'Activez la localisation de votre appareil puis réessayez.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('Partage de la position refusé.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Localisation bloquée : autorisez-la dans les réglages de l’appareil.',
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on Object {
      throw const LocationException('Position introuvable. Réessayez.');
    }
    return _reverseGeocode(position.latitude, position.longitude);
  }

  /// Garde les coordonnées exactes de l'utilisateur ; seul le nom vient
  /// du géocodage inverse. En cas d'échec, la ville s'appelle « Ma position ».
  Future<City> _reverseGeocode(double latitude, double longitude) async {
    var name = 'Ma position';
    var country = '';
    String? region;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '$latitude',
        'lon': '$longitude',
        'format': 'jsonv2',
        'zoom': '10',
        'accept-language': 'fr',
      });
      final response = await _client.get(
        uri,
        headers: const {'User-Agent': 'suivi-meteo-iot/1.0'},
      );
      if (response.statusCode == 200) {
        final json =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final address = json['address'] as Map<String, dynamic>? ?? const {};
        final place = [
          'city',
          'town',
          'village',
          'municipality',
          'state_district',
          'county',
        ].map((key) => address[key] as String?).nonNulls.firstOrNull;
        if (place != null) name = _strip(place);
        country = address['country'] as String? ?? '';
        region = switch (address['state'] as String?) {
          final state? => _strip(state),
          null => null,
        };
      }
    } on Object {
      // Nom générique conservé : la météo reste disponible pour la position.
    }
    return City(
      name: name,
      country: country,
      region: region,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static String _strip(String value) {
    for (final prefix in const ['Délégation ', 'Gouvernorat ']) {
      if (value.startsWith(prefix)) return value.substring(prefix.length);
    }
    return value;
  }
}
