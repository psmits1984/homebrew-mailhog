import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

enum BottomNavTab { polissen, offertes, betalingen, profiel }

class AppBottomNav extends StatelessWidget {
  final String entityId;
  final BottomNavTab currentTab;

  const AppBottomNav({
    super.key,
    required this.entityId,
    required this.currentTab,
  });

  void _onTap(BuildContext context, BottomNavTab tab) {
    if (tab == currentTab) return;
    switch (tab) {
      case BottomNavTab.polissen:
        context.go('/polissen/$entityId');
      case BottomNavTab.offertes:
        context.go('/entiteiten/$entityId/offertes');
      case BottomNavTab.betalingen:
        context.go('/entiteiten/$entityId/betalingen');
      case BottomNavTab.profiel:
        context.go('/entiteiten/$entityId/profiel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.shield_outlined,
                activeIcon: Icons.shield,
                label: 'Polissen',
                active: currentTab == BottomNavTab.polissen,
                onTap: () => _onTap(context, BottomNavTab.polissen),
              ),
              _NavItem(
                icon: Icons.description_outlined,
                activeIcon: Icons.description,
                label: 'Offertes',
                active: currentTab == BottomNavTab.offertes,
                onTap: () => _onTap(context, BottomNavTab.offertes),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Betalingen',
                active: currentTab == BottomNavTab.betalingen,
                onTap: () => _onTap(context, BottomNavTab.betalingen),
              ),
              _NavItem(
                icon: Icons.person_outlined,
                activeIcon: Icons.person,
                label: 'Profiel',
                active: currentTab == BottomNavTab.profiel,
                onTap: () => _onTap(context, BottomNavTab.profiel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
