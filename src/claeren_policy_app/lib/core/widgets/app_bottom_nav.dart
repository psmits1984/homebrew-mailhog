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

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      selectedIndex: currentTab.index,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        final tab = BottomNavTab.values[index];
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
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.shield_outlined),
          selectedIcon: Icon(Icons.shield, color: AppColors.primary),
          label: 'Polissen',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description, color: AppColors.primary),
          label: 'Offertes',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
          label: 'Betalingen',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'Profiel',
        ),
      ],
    );
  }
}
