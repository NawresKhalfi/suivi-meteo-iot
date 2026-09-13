import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/astronomy_repository.dart';
import '../domain/astronomy_snapshot.dart';

final astronomyRepositoryProvider = Provider<AstronomyRepository>(
  (ref) => DemoAstronomyRepository(),
);

final astronomyControllerProvider =
    AsyncNotifierProvider<AstronomyController, AstronomySnapshot>(
      AstronomyController.new,
    );

class AstronomyController extends AsyncNotifier<AstronomySnapshot> {
  AstronomyRepository get _repository => ref.read(astronomyRepositoryProvider);

  @override
  Future<AstronomySnapshot> build() => _repository.fetchToday();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.fetchToday);
  }
}
