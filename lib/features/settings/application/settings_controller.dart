import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_store.dart';
import '../domain/unit_formatter.dart';
import '../domain/unit_settings.dart';

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => MemorySettingsStore(),
);

final settingsControllerProvider =
    NotifierProvider<SettingsController, UnitSettings>(SettingsController.new);

/// Formateur à utiliser partout dans l'UI : suit les réglages en direct.
final unitFormatterProvider = Provider<UnitFormatter>(
  (ref) => UnitFormatter(ref.watch(settingsControllerProvider)),
);

class SettingsController extends Notifier<UnitSettings> {
  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  UnitSettings build() => _store.read();

  Future<void> update(UnitSettings Function(UnitSettings current) change) {
    state = change(state);
    return _store.save(state);
  }
}
