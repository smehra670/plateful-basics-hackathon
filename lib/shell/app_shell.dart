import 'package:flutter/material.dart';

import '../screens/ai_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/saved_lists_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/plateful_bottom_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            AiScreen(),
            CameraScreen(),
            SavedListsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: PlatefulBottomNav(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
      ),
    );
  }
}
