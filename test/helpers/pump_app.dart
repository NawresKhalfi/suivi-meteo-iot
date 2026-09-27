import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/app.dart';
import 'package:meteo/features/settings/data/home_screen_widget.dart';

import 'fakes.dart';

Future<void> settle(WidgetTester tester) async {
  // Animations infinies (repère pulsé) : on avance le temps sans pumpAndSettle.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Lance l'application complète avec les dépôts factices.
Future<void> pumpApp(
  WidgetTester tester, {
  FakeWeatherRepository? weather,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(weather: weather),
        ...overrides,
      ],
      child: const MeteoApp(),
    ),
  );
  await settle(tester);
}

/// Monte un widget isolé (feuille, panneau) dans un MaterialApp.
Future<void> pumpWidgetInApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...testOverrides(), ...overrides],
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await settle(tester);
}

/// Fait défiler la page (verticalement) jusqu'à rendre [finder] visible.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last,
  );
  await settle(tester);
}

/// Amène [finder] (déjà construit) à l'écran puis le touche.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settle(tester);
  await tester.tap(finder);
  await settle(tester);
}

/// Ouvre un onglet de la barre de navigation.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await settle(tester);
}

class FakeHomeScreenWidgetService implements HomeScreenWidgetService {
  FakeHomeScreenWidgetService({this.pinSupported = true});

  final bool pinSupported;
  final updates = <HomeScreenWidgetData>[];
  var pinRequests = 0;

  @override
  Future<bool> canPin() async => pinSupported;

  @override
  Future<void> requestPin() async => pinRequests++;

  @override
  Future<bool> isInstalled() async => pinRequests > 0;

  @override
  Future<void> update(HomeScreenWidgetData data) async => updates.add(data);
}
