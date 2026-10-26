import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/plateful_logo.dart';
import '../widgets/primary_button.dart';
import '../widgets/profile_avatar_button.dart';
import '../widgets/skeleton.dart';
import 'planner_setup_screen.dart';
import 'planner_timetable_screen.dart';

class PlannerTabScreen extends StatelessWidget {
  const PlannerTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.plannerLoading) {
      return const SafeArea(
        child: RecipeLoadingView(kind: LoadKind.planner),
      );
    }

    if (state.mealPlan != null) {
      return const PlannerTimetableScreen(embedded: true);
    }

    return const _PlannerLanding();
  }
}

class _PlannerLanding extends StatelessWidget {
  const _PlannerLanding();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, kFloatingNavClearance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: ProfileAvatarButton(),
            ),
            const Spacer(),
            const PlatefulLogo(height: 40),
            const SizedBox(height: 20),
            Text(
              'Plan a week\naround your kitchen.',
              style: AppText.h1(),
            ),
            const SizedBox(height: 12),
            Text(
              'We’ll use what’s already in your pantry and flag food that should be eaten first.',
              style: AppText.body(),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Create a meal plan',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlannerSetupScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => context.read<AppState>().setShellTab(1),
                child: Text(
                  'Add food to the pantry first',
                  style: AppText.label(color: AppColors.forest, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
