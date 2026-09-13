import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/cities_controller.dart';
import '../../domain/city.dart';

class CitiesScreen extends ConsumerStatefulWidget {
  const CitiesScreen({super.key});

  @override
  ConsumerState<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends ConsumerState<CitiesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(citiesControllerProvider);
    final cities = ref
        .read(citiesControllerProvider.notifier)
        .search(_searchController.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes villes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCity,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Ajouter'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Rechercher une ville',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          if (cities.isEmpty)
            const Center(child: Text('Aucune ville trouvée.')),
          ...cities.map(
            (city) => _CityTile(
              city: city,
              selected: city.id == state.selectedCityId,
              onSelect: () =>
                  ref.read(citiesControllerProvider.notifier).select(city),
              onFavorite: () => ref
                  .read(citiesControllerProvider.notifier)
                  .toggleFavorite(city),
              onDelete: () =>
                  ref.read(citiesControllerProvider.notifier).removeCity(city),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCity() async {
    final name = TextEditingController();
    final country = TextEditingController();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une ville'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Ville'),
            ),
            TextField(
              controller: country,
              decoration: const InputDecoration(labelText: 'Pays'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (name.text, country.text)),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    name.dispose();
    country.dispose();
    if (result != null) {
      await ref
          .read(citiesControllerProvider.notifier)
          .addCity(result.$1, result.$2);
    }
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.city,
    required this.selected,
    required this.onSelect,
    required this.onFavorite,
    required this.onDelete,
  });

  final City city;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onSelect,
        leading: Icon(
          selected ? Icons.location_on : Icons.location_on_outlined,
        ),
        title: Text(city.name),
        subtitle: Text(city.country),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onFavorite,
              icon: Icon(city.isFavorite ? Icons.star : Icons.star_border),
              tooltip: 'Favori',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}
