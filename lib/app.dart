import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/home_screen_widget_controller.dart';

class MeteoApp extends ConsumerWidget {
  const MeteoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeScreenWidgetSyncProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Prévisions Météo Locales',
      theme: AppTheme.light,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
