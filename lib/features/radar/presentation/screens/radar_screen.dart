import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({required this.layer, super.key});

  final String layer;

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  static const _layers = ['Pluie', 'Température', 'Vent', 'Nuages'];
  late final List<String> _rainFrames;

  late String _selectedLayer;
  Timer? _animationTimer;
  int _frameIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _selectedLayer = _layerLabel(widget.layer);
    final currentFrame = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _rainFrames = List.generate(
      6,
      (index) => '${currentFrame - (5 - index) * 600}',
    );
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRain = _selectedLayer == 'Pluie';
    return Scaffold(
      appBar: AppBar(title: const Text('Radar météo')),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(48.8566, 2.3522),
              initialZoom: 9,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.meteo.suivi_meteo_iot',
              ),
              if (isRain)
                Opacity(
                  opacity: 0.62,
                  child: TileLayer(
                    urlTemplate:
                        'https://tilecache.rainviewer.com/v2/radar/${_rainFrames[_frameIndex]}/256/{z}/{x}/{y}/2/1_1.png',
                    userAgentPackageName: 'com.meteo.suivi_meteo_iot',
                  ),
                ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 6,
                  children: _layers.map((layer) {
                    return ChoiceChip(
                      label: Text(layer),
                      selected: layer == _selectedLayer,
                      onSelected: (_) => setState(() => _selectedLayer = layer),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: isRain ? _toggleAnimation : null,
                      tooltip: _isPlaying
                          ? 'Mettre en pause'
                          : 'Lire l’animation',
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                    Text('Couche : $_selectedLayer'),
                    const Spacer(),
                    Text('Frame ${_frameIndex + 1}/${_rainFrames.length}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAnimation() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _animationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        setState(() => _frameIndex = (_frameIndex + 1) % _rainFrames.length);
      });
    } else {
      _animationTimer?.cancel();
      _animationTimer = null;
    }
  }

  static String _layerLabel(String value) {
    switch (value.toLowerCase()) {
      case 'temperature':
        return 'Température';
      case 'wind':
        return 'Vent';
      case 'clouds':
        return 'Nuages';
      default:
        return 'Pluie';
    }
  }
}
