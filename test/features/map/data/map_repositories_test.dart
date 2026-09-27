import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/features/map/data/map_repositories.dart';

void main() {
  test('analyse les images radar RainViewer', () {
    final frames = parseRainViewer({
      'host': 'https://tilecache.rainviewer.com',
      'radar': {
        'past': [
          {'time': 1790515200, 'path': '/v2/radar/a'},
          {'time': 1790515800, 'path': '/v2/radar/b'},
        ],
        'nowcast': [
          {'time': 1790516400, 'path': '/v2/radar/c'},
        ],
      },
    });
    expect(frames.frames, hasLength(3));
    expect(frames.nowIndex, 1);
    expect(frames.frames.last.isForecast, isTrue);
    expect(
      frames.tileUrl(frames.frames.first),
      'https://tilecache.rainviewer.com/v2/radar/a/256/{z}/{x}/{y}/2/1_1.png',
    );
  });
}
