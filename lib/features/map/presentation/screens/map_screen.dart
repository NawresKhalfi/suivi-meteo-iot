import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/pulsing_pin.dart';
import '../../../cities/application/cities_controller.dart';
import '../../../cities/domain/city.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/map_controller.dart';
import '../../domain/map_models.dart';
import '../widgets/map_overlays.dart';

/// Fournisseur de tuiles (surchargé en test pour éviter le réseau).
final mapTileProviderProvider = Provider<TileProvider>(
  (ref) => NetworkTileProvider(),
);

/// Carte radar : nuages, précipitations, vent en direct (E08).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _map = MapController();
  bool _mapReady = false;

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(selectedCityProvider);
    final cities = ref.watch(citiesControllerProvider).cities;
    final view = ref.watch(mapViewControllerProvider);
    final controller = ref.read(mapViewControllerProvider.notifier);
    final radar = ref.watch(radarFramesProvider);
    final grid = ref.watch(weatherGridProvider);
    final format = ref.watch(unitFormatterProvider);
    final tiles = ref.watch(mapTileProviderProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    ref.listen(selectedCityProvider, (_, next) {
      if (_mapReady) _map.move(LatLng(next.latitude, next.longitude), 8);
    });

    final isRadar = view.layer == MapLayer.precipitation;
    final frames = radar.valueOrNull;
    final points = grid.valueOrNull ?? const <GridPoint>[];
    final frameCount = controller.frameCount;
    final index = frameCount == 0
        ? 0
        : controller.currentIndex.clamp(0, frameCount - 1);
    final loading = isRadar ? radar.isLoading : grid.isLoading;
    final failed = isRadar ? radar.hasError : grid.hasError;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Carte radar',
              subtitle: 'Nuages, précipitations et vent en direct',
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _map,
                        options: MapOptions(
                          initialCenter: LatLng(city.latitude, city.longitude),
                          initialZoom: 10,
                          minZoom: 3,
                          maxZoom: 17,
                          backgroundColor: const Color(0xFFB7E4FA),
                          onMapReady: () => _mapReady = true,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            maxNativeZoom: 19,
                            userAgentPackageName: 'com.meteo.suivi_meteo_iot',
                            tileProvider: tiles,
                          ),
                          if (isRadar &&
                              frames != null &&
                              frames.frames.isNotEmpty)
                            Opacity(
                              opacity: 0.7,
                              child: TileLayer(
                                key: ValueKey(frames.frames[index].path),
                                urlTemplate: frames.tileUrl(
                                  frames.frames[index],
                                ),
                                maxNativeZoom: 7,
                                userAgentPackageName:
                                    'com.meteo.suivi_meteo_iot',
                                tileProvider: tiles,
                              ),
                            ),
                          if (!isRadar && points.isNotEmpty)
                            MarkerLayer(
                              markers: [
                                for (final point in points)
                                  if (point.hours.length > index)
                                    Marker(
                                      point: LatLng(
                                        point.latitude,
                                        point.longitude,
                                      ),
                                      width: 70,
                                      height: 30,
                                      child: GridValueMarker(
                                        layer: view.layer,
                                        hour: point.hours[index],
                                        format: format,
                                      ),
                                    ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              for (final c in cities)
                                Marker(
                                  point: LatLng(c.latitude, c.longitude),
                                  width: 48,
                                  height: 48,
                                  child: PulsingPin(pulse: c == city),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        top: 14,
                        left: 0,
                        right: 0,
                        child: _LayerChips(
                          selected: view.layer,
                          onSelected: controller.selectLayer,
                        ),
                      ),
                      if (loading)
                        const Positioned(
                          top: 60,
                          right: 14,
                          child: SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const _Attribution(),
                            const SizedBox(height: 6),
                            RadarPanel(
                              label: failed
                                  ? 'Couche indisponible — vérifiez la connexion'
                                  : _frameLabel(
                                      view.layer,
                                      frames,
                                      points,
                                      index,
                                      format.hour,
                                    ),
                              caption: _caption(view.layer, city),
                              frameCount: frameCount,
                              currentIndex: index,
                              isPlaying: view.isPlaying,
                              onTogglePlay: frameCount > 1
                                  ? controller.togglePlay
                                  : null,
                              onSelectFrame: controller.selectFrame,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _frameLabel(
    MapLayer layer,
    RadarFrames? frames,
    List<GridPoint> points,
    int index,
    String Function(DateTime) hour,
  ) {
    if (layer == MapLayer.precipitation) {
      if (frames == null || frames.frames.isEmpty) {
        return 'Chargement du radar…';
      }
      final frame = frames.frames[index];
      final minutes = frame.time
          .difference(frames.frames[frames.nowIndex].time)
          .inMinutes;
      if (minutes == 0) return 'Maintenant';
      return minutes < 0 ? 'Il y a ${-minutes} min' : 'Prévision +$minutes min';
    }
    if (points.isEmpty || points.first.hours.isEmpty) return 'Chargement…';
    return index == 0
        ? 'Maintenant'
        : 'Prévision ${hour(points.first.hours[index].time)}';
  }

  static String _caption(MapLayer layer, City city) => switch (layer) {
    MapLayer.precipitation => 'Radar des précipitations · 2 dernières heures',
    MapLayer.temperature => 'Température autour de ${city.name}',
    MapLayer.wind => 'Vent moyen et direction autour de ${city.name}',
    MapLayer.clouds => 'Couverture nuageuse autour de ${city.name}',
  };
}

class _LayerChips extends StatelessWidget {
  const _LayerChips({required this.selected, required this.onSelected});

  final MapLayer selected;
  final ValueChanged<MapLayer> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          for (final layer in MapLayer.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: layer == selected
                    ? AppColors.primary1
                    : const Color(0xD9FFFFFF),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(layer),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    child: Text(
                      layer.label,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: layer == selected
                            ? Colors.white
                            : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xB3FFFFFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '© OpenStreetMap · RainViewer · Open-Meteo',
        style: TextStyle(fontSize: 9, color: AppColors.inkSoft),
      ),
    );
  }
}
