import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/local_preferences.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/alerts/application/alert_watcher.dart';
import 'features/alerts/application/alerts_controller.dart';
import 'features/alerts/data/alerts_repository.dart';
import 'features/cities/application/cities_controller.dart';
import 'features/cities/data/cities_store.dart';
import 'features/settings/application/home_screen_widget_controller.dart';
import 'features/settings/data/home_screen_widget.dart';
import 'features/settings/application/settings_controller.dart';
import 'features/settings/data/settings_store.dart';
import 'features/weather/application/weather_controller.dart';
import 'features/weather/data/weather_cache_store.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: InitApp()));
}

class _InitData {
  const _InitData(this.preferences);

  final LocalPreferences preferences;
}

final _initProvider = FutureProvider<_InitData>((ref) async {
  final preferences = LocalPreferences(await SharedPreferences.getInstance());
  try {
    await LocalAlertNotificationService.start(preferences);
  } on Object catch (error) {
    debugPrint('Surveillance des alertes indisponible : $error');
  }
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  } on Object catch (error) {
    // Firebase non configuré (fichiers google-services absents). Les alertes
    // sont notifiées localement par la surveillance en arrière-plan.
    debugPrint('Firebase indisponible : $error');
  }
  return _InitData(preferences);
});

class InitApp extends ConsumerWidget {
  const InitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(_initProvider)
        .when(
          loading: () => const _Splash(),
          error: (error, _) => const _Splash(
            message: 'Initialisation impossible. Relancez l’application.',
          ),
          data: (data) {
            final prefs = data.preferences;
            return ProviderScope(
              overrides: [
                citiesStoreProvider.overrideWithValue(
                  SharedPreferencesCitiesStore(prefs),
                ),
                settingsStoreProvider.overrideWithValue(
                  SharedPreferencesSettingsStore(prefs),
                ),
                weatherCacheStoreProvider.overrideWithValue(
                  SharedPreferencesWeatherCacheStore(prefs),
                ),
                alertsHistoryStoreProvider.overrideWithValue(
                  SharedPreferencesAlertsHistoryStore(prefs),
                ),
                alertNotificationServiceProvider.overrideWithValue(
                  LocalAlertNotificationService(prefs),
                ),
                homeScreenWidgetServiceProvider.overrideWithValue(
                  platformHomeScreenWidget(),
                ),
              ],
              child: const MeteoApp(),
            );
          },
        );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: Center(
            child: message == null
                ? const CircularProgressIndicator(color: Colors.white)
                : Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
