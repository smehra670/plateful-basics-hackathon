import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/chef_screen.dart';
import '../screens/pantry_screen.dart';
import '../screens/scan_screen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/plateful_bottom_nav.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: IndexedStack(
        index: state.shellTabIndex,
        children: const [
          ChefScreen(),
          ScanScreen(),
          PantryScreen(),
        ],
      ),
      bottomNavigationBar: PlatefulBottomNav(
        currentIndex: state.shellTabIndex,
        onTap: (index) => context.read<AppState>().setShellTab(index),
      ),
    );
  }
}
