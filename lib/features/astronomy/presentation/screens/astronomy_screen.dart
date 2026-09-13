import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/astronomy_controller.dart';
import '../../domain/astronomy_snapshot.dart';

class AstronomyScreen extends ConsumerStatefulWidget {
  const AstronomyScreen({super.key});

  @override
  ConsumerState<AstronomyScreen> createState() => _AstronomyScreenState();
}

class _AstronomyScreenState extends ConsumerState<AstronomyScreen> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final astronomy = ref.watch(astronomyControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Soleil et lune')),
      body: astronomy.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(astronomyControllerProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
        data: (snapshot) => RefreshIndicator(
          onRefresh: () =>
              ref.read(astronomyControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _SunCycle(snapshot: snapshot, now: _now),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: Text(
                    snapshot.moonPhase.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  title: Text(snapshot.moonPhase.label),
                  subtitle: const Text('Phase lunaire du jour'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SunCycle extends StatelessWidget {
  const _SunCycle({required this.snapshot, required this.now});

  final AstronomySnapshot snapshot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final total = snapshot.sunset.difference(snapshot.sunrise).inMinutes;
    final elapsed = now.difference(snapshot.sunrise).inMinutes;
    final progress = (elapsed / total).clamp(0.0, 1.0);
    final isDay =
        now.isAfter(snapshot.sunrise) && now.isBefore(snapshot.sunset);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle du jour',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.wb_twilight),
                Icon(isDay ? Icons.wb_sunny : Icons.nightlight_round),
                const Icon(Icons.nights_stay_outlined),
              ],
            ),
            Slider(value: progress, onChanged: null),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lever ${_time(snapshot.sunrise)}'),
                Text('Coucher ${_time(snapshot.sunset)}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(isDay ? 'Jour en cours' : 'Nuit en cours'),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
