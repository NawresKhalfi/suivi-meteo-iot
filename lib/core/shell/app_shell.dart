import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class _TabItem {
  const _TabItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _tabs = [
  _TabItem('Accueil', Icons.home_outlined, Icons.home_rounded),
  _TabItem(
    'Prévisions',
    Icons.calendar_month_outlined,
    Icons.calendar_month_rounded,
  ),
  _TabItem('Carte', Icons.map_outlined, Icons.map_rounded),
  _TabItem('Villes', Icons.location_city_outlined, Icons.location_city_rounded),
  _TabItem('Réglages', Icons.settings_outlined, Icons.settings_rounded),
];

/// Structure principale : 5 onglets avec barre translucide floutée.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class AppTabBar extends StatelessWidget {
  const AppTabBar({required this.currentIndex, required this.onTap, super.key});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xE0FFFFFF),
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          padding: EdgeInsets.fromLTRB(6, 10, 6, 10 + bottomInset * 0.6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                _TabButton(
                  item: _tabs[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _TabItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary1 : AppColors.inkFaint;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 26,
                decoration: BoxDecoration(
                  color: active ? AppColors.surfaceSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
