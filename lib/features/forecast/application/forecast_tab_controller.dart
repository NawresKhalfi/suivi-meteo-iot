import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ForecastTab {
  hours24('24 heures'),
  days10('10 jours'),
  rainWind('Pluie & vent');

  const ForecastTab(this.label);
  final String label;
}

final forecastTabProvider =
    NotifierProvider<ForecastTabController, ForecastTab>(
      ForecastTabController.new,
    );

class ForecastTabController extends Notifier<ForecastTab> {
  @override
  ForecastTab build() => ForecastTab.hours24;

  void select(ForecastTab tab) => state = tab;
}
