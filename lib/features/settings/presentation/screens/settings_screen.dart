import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../core/widgets/weather_icon.dart';
import '../../../alerts/application/alerts_controller.dart';
import '../../../cities/application/cities_controller.dart';
import '../../../weather/application/weather_controller.dart';
import '../../../weather/domain/weather_condition.dart';
import '../../application/home_screen_widget_controller.dart';
import '../../application/settings_controller.dart';
import '../../domain/unit_settings.dart';
import '../widgets/settings_widgets.dart';

/// Réglages : unités, formats, notifications, widget (E11, E12).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final alertsEnabled = ref.watch(alertNotificationsEnabledProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    Future<void> pick<T extends Enum>({
      required String title,
      required List<T> options,
      required T selected,
      required String Function(T) label,
      required UnitSettings Function(UnitSettings, T) apply,
    }) async {
      final choice = await showOptionPicker<T>(
        context,
        title: title,
        options: options,
        selected: selected,
        label: label,
      );
      if (choice == null || choice == selected) return;
      await controller.update((s) => apply(s, choice));
      if (context.mounted) {
        showToast(context, '$title mis à jour : ${label(choice)}');
      }
    }

    Future<void> toggleAlerts() async {
      final notifier = ref.read(alertNotificationsEnabledProvider.notifier);
      try {
        alertsEnabled ? await notifier.disable() : await notifier.enable();
        if (context.mounted) {
          showToast(
            context,
            'Alertes météo : ${alertsEnabled ? 'désactivées' : 'activées'}',
          );
        }
      } on Object {
        if (context.mounted) {
          showToast(
            context,
            'Autorisez les notifications dans les réglages du téléphone',
          );
        }
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottom + 24),
          children: [
            const PageHeader(
              title: 'Réglages',
              subtitle: 'Unités, formats et notifications',
            ),
            SettingsGroup(
              title: 'Unités de mesure',
              children: [
                SettingsRow(
                  icon: Icons.thermostat_rounded,
                  colors: (AppColors.sun1, AppColors.sun2),
                  label: 'Température',
                  value: settings.temperature.label,
                  onTap: () => pick(
                    title: 'Température',
                    options: TemperatureUnit.values,
                    selected: settings.temperature,
                    label: (v) => v.label,
                    apply: (s, v) => s.copyWith(temperature: v),
                  ),
                ),
                SettingsRow(
                  icon: Icons.water_drop_rounded,
                  colors: (AppColors.rain1, AppColors.rain2),
                  label: 'Précipitations',
                  value: settings.precipitation.label,
                  onTap: () => pick(
                    title: 'Précipitations',
                    options: PrecipitationUnit.values,
                    selected: settings.precipitation,
                    label: (v) => v.label,
                    apply: (s, v) => s.copyWith(precipitation: v),
                  ),
                ),
                SettingsRow(
                  icon: Icons.visibility_rounded,
                  colors: (const Color(0xFF38B6E0), AppColors.primary1),
                  label: 'Visibilité',
                  value: settings.visibility.label,
                  onTap: () => pick(
                    title: 'Visibilité',
                    options: VisibilityUnit.values,
                    selected: settings.visibility,
                    label: (v) => v.label,
                    apply: (s, v) => s.copyWith(visibility: v),
                  ),
                ),
                SettingsRow(
                  icon: Icons.air_rounded,
                  colors: (AppColors.wind1, AppColors.wind2),
                  label: 'Vitesse du vent',
                  value: settings.windSpeed.label,
                  onTap: () => pick(
                    title: 'Vitesse du vent',
                    options: WindSpeedUnit.values,
                    selected: settings.windSpeed,
                    label: (v) => v.label,
                    apply: (s, v) => s.copyWith(windSpeed: v),
                  ),
                ),
                SettingsRow(
                  icon: Icons.speed_rounded,
                  colors: (AppColors.inkSoft, AppColors.ink),
                  label: 'Pression',
                  value: settings.pressure.label,
                  onTap: () => pick(
                    title: 'Pression atmosphérique',
                    options: PressureUnit.values,
                    selected: settings.pressure,
                    label: (v) => v.label,
                    apply: (s, v) => s.copyWith(pressure: v),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: "Format d'affichage",
              children: [
                SettingsRow(
                  icon: Icons.schedule_rounded,
                  colors: (AppColors.primary1, AppColors.primary2),
                  label: "Format de l'heure",
                  value: settings.timeFormat.label,
                  onTap: () => pick(
                    title: "Format de l'heure",
                    options: TimeFormat.values,
                    selected: settings.timeFormat,
                    label: (v) => v.label,
                    apply: (s, v) => s.copyWith(timeFormat: v),
                  ),
                ),
                SettingsRow(
                  icon: Icons.calendar_today_rounded,
                  colors: (AppColors.primary1, AppColors.primary2),
                  label: 'Format de date',
                  value: settings.datePattern.label,
                  onTap: () => pick(
                    title: 'Format de date',
                    options: DatePattern.values,
                    selected: settings.datePattern,
                    label: (v) => v.label,
                    apply: (s, v) => s.copyWith(datePattern: v),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Notifications',
              children: [
                SettingsRow(
                  icon: Icons.notifications_active_rounded,
                  colors: (AppColors.alert1, AppColors.alert2),
                  label: 'Alertes météo',
                  trailing: AppSwitch(value: alertsEnabled),
                  onTap: toggleAlerts,
                ),
                SettingsRow(
                  icon: Icons.article_rounded,
                  colors: (AppColors.sun1, AppColors.sun2),
                  label: 'Résumé quotidien',
                  trailing: AppSwitch(value: settings.dailySummaryEnabled),
                  onTap: () async {
                    final enabled = !settings.dailySummaryEnabled;
                    await controller.update(
                      (s) => s.copyWith(dailySummaryEnabled: enabled),
                    );
                    if (context.mounted) {
                      showToast(
                        context,
                        'Résumé quotidien : ${enabled ? 'activé' : 'désactivé'}',
                      );
                    }
                  },
                ),
              ],
            ),
            const _WidgetPreview(),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Text(
                'Données météo et qualité de l’air : Open-Meteo · Radar : RainViewer · '
                'Fonds de carte : © OpenStreetMap',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.inkFaint,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aperçu du widget d'écran d'accueil avec les données réelles.
class _WidgetPreview extends ConsumerWidget {
  const _WidgetPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);
    final current = ref.watch(weatherControllerProvider).valueOrNull?.current;
    final format = ref.watch(unitFormatterProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              "Widget d'écran d'accueil",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.inkFaint,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _offerHomeScreenWidget(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.shadowMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              city.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xD9FFFFFF),
                              ),
                            ),
                            Text(
                              current == null
                                  ? '--°'
                                  : format.temperature(current.temperature),
                              style: const TextStyle(
                                fontFamily: AppFonts.display,
                                fontWeight: FontWeight.w800,
                                fontSize: 30,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (current != null)
                        HeroWeatherIcon(
                          current.condition.icon(isDay: current.isDay),
                          size: 40,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    current == null
                        ? 'Aperçu du widget'
                        : '${current.condition.label(isDay: current.isDay)} · '
                              'aperçu — mis à jour toutes les 30 min',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xB3FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "Toucher pour l'ajouter à l'écran d'accueil",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Propose d'ajouter le widget, puis ouvre la confirmation du système.
Future<void> _offerHomeScreenWidget(BuildContext context, WidgetRef ref) async {
  final canPin = await ref.read(homeScreenWidgetServiceProvider).canPin();
  if (!context.mounted) return;
  final city = ref.read(citiesControllerProvider).defaultCityOrFirst;
  final accepted = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x73091E30),
    builder: (_) => _AddWidgetDialog(cityName: city.name, canPin: canPin),
  );
  if (accepted != true || !context.mounted) return;
  try {
    await pinHomeScreenWidget(ref);
  } on Object {
    if (context.mounted) {
      showToast(context, "Impossible d'ajouter le widget sur ce téléphone");
    }
  }
}

class _AddWidgetDialog extends StatelessWidget {
  const _AddWidgetDialog({required this.cityName, required this.canPin});

  final String cityName;
  final bool canPin;

  @override
  Widget build(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final message = canPin
        ? 'Affichez la température et le ciel de $cityName directement sur '
              "l'écran d'accueil de votre téléphone. Le widget se met à jour "
              'automatiquement toutes les 30 minutes environ.'
        : isAndroid
        ? "Votre écran d'accueil ne permet pas l'ajout automatique. Faites un "
              "appui long sur l'écran d'accueil, choisissez « Widgets » puis "
              '« Météo ».'
        : "Le widget d'écran d'accueil est pour l'instant disponible "
              'uniquement sur Android.';
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppColors.shadowMd,
                ),
                child: const Icon(
                  Icons.widgets_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              canPin
                  ? "Ajouter le widget à l'écran d'accueil ?"
                  : 'Widget météo',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 18),
            if (canPin) ...[
              AppButton(
                label: 'Ajouter',
                onPressed: () => Navigator.of(context).pop(true),
              ),
              AppButton(
                label: 'Pas maintenant',
                style: AppButtonStyle.ghost,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ] else
              AppButton(
                label: "J'ai compris",
                onPressed: () => Navigator.of(context).pop(false),
              ),
          ],
        ),
      ),
    );
  }
}
