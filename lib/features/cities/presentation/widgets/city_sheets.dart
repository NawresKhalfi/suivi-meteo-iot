import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/toast.dart';
import '../../../../core/widgets/weather_icon.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../weather/application/weather_controller.dart';
import '../../../weather/domain/weather_condition.dart';
import '../../application/cities_controller.dart';
import '../../domain/city.dart';

const starIcon = Icon(Icons.star_rounded, color: AppColors.sun1, size: 16);

/// « Changer de ville » depuis l'accueil (E10 – US27).
class CitySwitchSheet extends ConsumerWidget {
  const CitySwitchSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(citiesControllerProvider);
    final weather = ref.watch(citiesWeatherProvider).valueOrNull ?? const {};
    final format = ref.watch(unitFormatterProvider);
    return AppSheet(
      title: 'Changer de ville',
      children: [
        for (final city in state.cities)
          SuggestRow(
            leading: weather[city.id] == null
                ? const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.inkFaint,
                  )
                : WeatherIcon(
                    weather[city.id]!.condition.icon(
                      isDay: weather[city.id]!.isDay,
                    ),
                    size: 26,
                  ),
            title: city.name,
            titleTrailing: state.isDefault(city) ? starIcon : null,
            subtitle: city.subtitle,
            selected: city.id == state.selectedCityId,
            trailing: Text(
              weather[city.id] == null
                  ? ''
                  : format.temperature(weather[city.id]!.temperature),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            onTap: () {
              ref.read(citiesControllerProvider.notifier).select(city);
              Navigator.of(context).pop();
              showToast(context, 'Ville sélectionnée : ${city.name}');
            },
          ),
        AppButton(
          label: 'Gérer mes villes',
          style: AppButtonStyle.ghost,
          onPressed: () {
            Navigator.of(context).pop();
            context.go(AppRoutes.cities);
          },
        ),
      ],
    );
  }
}

/// Recherche et ajout d'une ville (E10 – US26).
class AddCitySheet extends ConsumerStatefulWidget {
  const AddCitySheet({super.key});

  @override
  ConsumerState<AddCitySheet> createState() => _AddCitySheetState();
}

class _AddCitySheetState extends ConsumerState<AddCitySheet> {
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  String? _error;
  List<City> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value.trim());
    if (_query.length < 2) {
      setState(() {
        _loading = false;
        _error = null;
        _results = const [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(_query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(citySearchRepositoryProvider)
          .search(query);
      if (!mounted || query != _query) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Recherche impossible. Vérifiez votre connexion.';
      });
    }
  }

  Future<void> _add(City city) async {
    final added = await ref
        .read(citiesControllerProvider.notifier)
        .addCity(city);
    if (!mounted) return;
    Navigator.of(context).pop();
    showToast(
      context,
      added
          ? '${city.name} a été ajoutée à vos villes'
          : '${city.name} est déjà dans vos villes',
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPopular = _query.length < 2;
    final list = showPopular ? popularCities : _results;
    return AppSheet(
      title: 'Ajouter une ville',
      children: [
        const SizedBox(height: 4),
        TextField(
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Rechercher une ville...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.inkFaint,
            ),
            filled: true,
            fillColor: AppColors.surfaceSoft,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary2, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (showPopular)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.inkFaint,
              ),
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _EmptyText(_error!)
        else if (list.isEmpty)
          const _EmptyText('Aucune ville trouvée')
        else
          for (final city in list)
            SuggestRow(
              title: city.name,
              subtitle: city.subtitle,
              trailing: const Icon(
                Icons.add_rounded,
                color: AppColors.primary1,
              ),
              onTap: () => _add(city),
            ),
      ],
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.inkFaint, fontSize: 13),
    ),
  );
}

/// Confirmation de suppression (E10 – US29). Renvoie `true` si confirmé.
class DeleteCitySheet extends StatelessWidget {
  const DeleteCitySheet({required this.city, super.key});

  final City city;

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Supprimer cette ville ?',
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Cette action retirera '),
              TextSpan(
                text: city.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                text:
                    ' de votre liste de villes suivies. Vous pourrez '
                    "l'ajouter à nouveau plus tard.",
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.55,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Supprimer',
          style: AppButtonStyle.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        AppButton(
          label: 'Annuler',
          style: AppButtonStyle.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

/// Ligne de liste des sheets (suggestions, villes).
class SuggestRow extends StatelessWidget {
  const SuggestRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
    this.titleTrailing,
    this.selected = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? titleTrailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: selected
                                ? AppColors.primary1
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      if (titleTrailing != null) ...[
                        const SizedBox(width: 4),
                        titleTrailing!,
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkFaint,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
