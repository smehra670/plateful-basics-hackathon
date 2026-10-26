import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/pantry_import_screen.dart';
import '../screens/pantry_screen.dart';
import '../screens/planner_tab_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_nav_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: Stack(
        children: [
          IndexedStack(
            index: state.shellTabIndex,
            children: const [
              PlannerTabScreen(),
              PantryImportScreen(asTab: true),
              PantryScreen(),
            ],
          ),
          FloatingNavBar(
            currentIndex: state.shellTabIndex,
            onTap: (index) => context.read<AppState>().setShellTab(index),
          ),
        ],
      ),
    );
  }
}
