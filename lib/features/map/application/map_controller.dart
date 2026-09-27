import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/http_client_provider.dart';
import '../../cities/application/cities_controller.dart';
import '../data/map_repositories.dart';
import '../domain/map_models.dart';

final radarRepositoryProvider = Provider<RadarRepository>(
  (ref) => RainViewerRadarRepository(ref.watch(httpClientProvider)),
);

final weatherGridRepositoryProvider = Provider<WeatherGridRepository>(
  (ref) => OpenMeteoWeatherGridRepository(ref.watch(httpClientProvider)),
);

final radarFramesProvider = FutureProvider<RadarFrames>(
  (ref) => ref.read(radarRepositoryProvider).fetchFrames(),
);

final weatherGridProvider = FutureProvider<List<GridPoint>>((ref) {
  final city = ref.watch(selectedCityProvider);
  return ref.read(weatherGridRepositoryProvider).fetchGrid(city);
});

class MapViewState {
  const MapViewState({
    this.layer = MapLayer.temperature,
    this.frameIndex,
    this.isPlaying = false,
  });

  final MapLayer layer;

  /// `null` = image « Maintenant » de la couche.
  final int? frameIndex;
  final bool isPlaying;

  MapViewState copyWith({
    MapLayer? layer,
    int? Function()? frameIndex,
    bool? isPlaying,
  }) {
    return MapViewState(
      layer: layer ?? this.layer,
      frameIndex: frameIndex != null ? frameIndex() : this.frameIndex,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

final mapViewControllerProvider =
    NotifierProvider<MapViewController, MapViewState>(MapViewController.new);

/// Couche affichée et animation (E08 – US21 à US23).
class MapViewController extends Notifier<MapViewState> {
  Timer? _timer;

  @override
  MapViewState build() {
    ref.onDispose(() => _timer?.cancel());
    return const MapViewState();
  }

  int get frameCount => switch (state.layer) {
    MapLayer.precipitation =>
      ref.read(radarFramesProvider).valueOrNull?.frames.length ?? 0,
    _ =>
      ref.read(weatherGridProvider).valueOrNull?.firstOrNull?.hours.length ?? 0,
  };

  int get nowIndex => state.layer == MapLayer.precipitation
      ? ref.read(radarFramesProvider).valueOrNull?.nowIndex ?? 0
      : 0;

  int get currentIndex => state.frameIndex ?? nowIndex;

  void selectLayer(MapLayer layer) {
    _stop();
    state = MapViewState(layer: layer);
  }

  void selectFrame(int index) {
    _stop();
    state = state.copyWith(frameIndex: () => index, isPlaying: false);
  }

  void togglePlay() {
    if (state.isPlaying) {
      _stop();
      state = state.copyWith(isPlaying: false);
      return;
    }
    if (frameCount < 2) return;
    // Pour le radar, l'animation repart de la plus ancienne image.
    state = state.copyWith(isPlaying: true, frameIndex: () => 0);
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      final count = frameCount;
      if (count == 0) return;
      state = state.copyWith(frameIndex: () => (currentIndex + 1) % count);
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}
