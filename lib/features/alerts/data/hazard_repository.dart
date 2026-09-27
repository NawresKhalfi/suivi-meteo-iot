import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/http_client_provider.dart';
import '../domain/hazard_event.dart';

abstract interface class HazardRepository {
  /// Catastrophes naturelles en cours dans le monde.
  Future<List<HazardEvent>> fetchCurrentEvents();
}

/// API publique GDACS (Global Disaster Alert and Coordination System) :
/// incendies, inondations, séismes, cyclones, volcans et sécheresses en cours.
class GdacsHazardRepository implements HazardRepository {
  GdacsHazardRepository(this._client);

  final http.Client _client;

  @override
  Future<List<HazardEvent>> fetchCurrentEvents() async {
    final results = await Future.wait(
      HazardType.values.map((type) async {
        try {
          final response = await _client.get(
            Uri.https(
              'www.gdacs.org',
              '/gdacsapi/api/events/geteventlist/MAP',
              {'eventtype': type.code},
            ),
          );
          if (response.statusCode != 200) return null;
          return parseGdacsEvents(
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
          );
        } on Object {
          return null;
        }
      }),
    );
    if (results.every((r) => r == null)) {
      throw const ApiException('Alertes GDACS indisponibles.');
    }
    return [for (final events in results) ...?events];
  }
}

/// Garde un point (le centroïde) par événement GDACS.
List<HazardEvent> parseGdacsEvents(Map<String, dynamic> json) {
  final events = <HazardEvent>[];
  final seen = <String>{};
  for (final item in json['features'] as List<dynamic>? ?? const []) {
    final feature = item as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final props = feature['properties'] as Map<String, dynamic>?;
    if (geometry?['type'] != 'Point' || props == null) continue;
    if (props['Class'] != 'Point_Centroid') continue;
    final type = HazardType.fromCode(props['eventtype'] as String? ?? '');
    final id = '${props['eventid']}';
    if (type == null || !seen.add('${type.code}-$id')) continue;
    final coordinates = geometry!['coordinates'] as List<dynamic>;
    final from = _utc(props['fromdate']);
    final to = _utc(props['todate']);
    if (from == null || to == null) continue;
    events.add(
      HazardEvent(
        id: id,
        type: type,
        level: switch ((props['alertlevel'] as String? ?? '').toLowerCase()) {
          'red' => HazardLevel.red,
          'orange' => HazardLevel.orange,
          _ => HazardLevel.green,
        },
        name: props['name'] as String? ?? '',
        country: props['country'] as String? ?? '',
        longitude: (coordinates[0] as num).toDouble(),
        latitude: (coordinates[1] as num).toDouble(),
        from: from,
        to: to,
        description:
            props['htmldescription'] as String? ??
            props['description'] as String? ??
            '',
        severityText:
            (props['severitydata'] as Map<String, dynamic>?)?['severitytext']
                as String?,
      ),
    );
  }
  return events;
}

/// GDACS publie ses dates en UTC sans suffixe « Z ».
DateTime? _utc(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(
    value.endsWith('Z') ? value : '${value}Z',
  )?.toLocal();
}
