import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meteo/core/network/http_client_provider.dart';
import 'package:meteo/features/cities/data/city_search_repository.dart';

final _openMeteo = {
  'results': [
    {
      'name': 'Hammam Sousse',
      'country': 'Tunisie',
      'admin1': 'Sousse',
      'latitude': 35.8609,
      'longitude': 10.6031,
    },
    {
      'name': 'Sfax',
      'country': 'Tunisie',
      'admin1': 'Sfax',
      'latitude': 34.7406,
      'longitude': 10.7603,
    },
  ],
};

final _photon = {
  'features': [
    // Même ville qu'Open-Meteo, à moins de 5 km : doublon ignoré.
    {
      'properties': {
        'name': 'Délégation Hammam Sousse',
        'country': 'Tunisie',
        'state': 'Gouvernorat Sousse',
      },
      'geometry': {
        'coordinates': [10.60, 35.86],
      },
    },
    {
      'properties': {
        'name': 'Délégation Monastir',
        'country': 'Tunisie',
        'state': 'Gouvernorat Monastir',
      },
      'geometry': {
        'coordinates': [10.8262, 35.7643],
      },
    },
    {
      'properties': {'country': 'Tunisie'},
      'geometry': {
        'coordinates': [10, 35],
      },
    },
  ],
};

http.Response _json(Object body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), 200);

void main() {
  test('US26 : fusionne Open-Meteo et Photon sans doublon', () async {
    final hosts = <String>[];
    final repository = OpenMeteoCitySearchRepository(
      MockClient((request) async {
        hosts.add(request.url.host);
        return request.url.host == 'photon.komoot.io'
            ? _json(_photon)
            : _json(_openMeteo);
      }),
    );
    final cities = await repository.search('  sous ');
    expect(
      hosts,
      containsAll(['geocoding-api.open-meteo.com', 'photon.komoot.io']),
    );
    expect(cities.map((c) => c.name), ['Hammam Sousse', 'Sfax', 'Monastir']);
    final monastir = cities.last;
    expect(monastir.region, 'Monastir'); // préfixe « Gouvernorat » retiré
    expect(monastir.latitude, 35.7643);
    expect(monastir.longitude, 10.8262);
    expect(cities.first.region, 'Sousse');
  });

  test('moins de deux caractères : aucune requête', () async {
    var calls = 0;
    final repository = OpenMeteoCitySearchRepository(
      MockClient((_) async {
        calls++;
        return _json(_openMeteo);
      }),
    );
    expect(await repository.search(' s '), isEmpty);
    expect(calls, 0);
  });

  test('une source en panne : l’autre prend le relais', () async {
    final repository = OpenMeteoCitySearchRepository(
      MockClient(
        (request) async => request.url.host == 'photon.komoot.io'
            ? http.Response('', 500)
            : _json(_openMeteo),
      ),
    );
    final cities = await repository.search('sousse');
    expect(cities.map((c) => c.name), ['Hammam Sousse', 'Sfax']);
  });

  test('les deux sources en panne : ApiException', () {
    final repository = OpenMeteoCitySearchRepository(
      MockClient((_) async => http.Response('', 503)),
    );
    expect(repository.search('sousse'), throwsA(isA<ApiException>()));
  });

  test('au plus 10 résultats', () async {
    final many = {
      'results': [
        for (var i = 0; i < 12; i++)
          {
            'name': 'Ville $i',
            'country': 'Tunisie',
            'latitude': 30.0 + i,
            'longitude': 10.0,
          },
      ],
    };
    final repository = OpenMeteoCitySearchRepository(
      MockClient(
        (request) async => request.url.host == 'photon.komoot.io'
            ? _json({'features': <Object>[]})
            : _json(many),
      ),
    );
    expect(await repository.search('ville'), hasLength(10));
  });
}
