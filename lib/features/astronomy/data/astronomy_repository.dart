import '../domain/astronomy_snapshot.dart';

abstract interface class AstronomyRepository {
  Future<AstronomySnapshot> fetchToday();
}

class DemoAstronomyRepository implements AstronomyRepository {
  @override
  Future<AstronomySnapshot> fetchToday() async {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 6, 45);
    final evening = DateTime(now.year, now.month, now.day, 20, 35);
    return AstronomySnapshot(
      sunrise: morning,
      sunset: evening,
      moonPhase: moonPhaseForDate(now),
      observedAt: now,
    );
  }
}
