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

  void _onTap(BuildContext context, int index) {
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
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentTab.index,
      onTap: (index) => _onTap(context, index),
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shield_outlined),
          activeIcon: Icon(Icons.shield),
          label: 'Polissen',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'Offertes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Betalingen',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: 'Profiel',
        ),
      ],
    );
  }
}
