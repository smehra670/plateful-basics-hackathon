import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/pantry_match.dart';
import '../theme/app_theme.dart';
import '../models/meal_plan.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/primary_button.dart';
import '../widgets/recipe_photo.dart';
import '../widgets/skeleton.dart';
import '../widgets/swipe_deck.dart';
import 'course_select_screen.dart';
import 'planner_setup_screen.dart';
import 'recipe_detail_screen.dart';

class ChefScreen extends StatelessWidget {
  const ChefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: Column(
          children: [
            if (!state.serverReachable) const _ServerBanner(),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppState state) {
    switch (state.chefPhase) {
      case ChefPhase.loading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: CircleIconButton(
                icon: PhosphorIconsRegular.arrowLeft,
                semanticLabel: 'Back',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            const Expanded(child: RecipeLoadingView(kind: LoadKind.recipes)),
          ],
        );
      case ChefPhase.swiping:
        return SwipeDeck(
          key: ValueKey(state.deck.map((r) => r.id).join('|')),
          recipes: state.deck,
          savedIds: state.savedIds,
          currentIndex: state.swipeIndex,
          onLike: state.likeCurrent,
          onReject: state.rejectCurrent,
          onUndo: state.undoSwipe,
          onHeart: state.toggleSave,
          expiringCount: (recipe) => _expiringUses(state, recipe),
        );
      case ChefPhase.results:
        return _ResultsView(state: state);
      case ChefPhase.idle:
        return _IdleView(state: state);
    }
  }
}

int _expiringUses(AppState state, Recipe recipe) {
  return state.useSoonIngredients
      .where(
        (item) => recipe.ingredients.any(
          (ingredient) =>
              ingredient.inPantry && pantryNamesMatch(ingredient.name, item.name),
        ),
      )
      .length;
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleIconButton(
            icon: PhosphorIconsRegular.arrowLeft,
            semanticLabel: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          Text(
            state.error == null ? 'No recipes yet.' : 'Couldn’t create recipes.',
            style: AppText.h1Small(),
          ),
          const SizedBox(height: 10),
          Text(
            state.error ??
                'Pick a course from your pantry and we’ll write dishes around what you have.',
            style: AppText.body(),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Try again',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const CourseSelectScreen(fromPantry: true),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ServerBanner extends StatelessWidget {
  const _ServerBanner();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Material(
      color: AppColors.roseSoft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            const Icon(
              PhosphorIconsRegular.prohibit,
              color: AppColors.roseText,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.reconnecting
                    ? 'Checking Plateful server…'
                    : 'Server offline. On PC run .\\start-plateful.ps1, keep USB in, then Retry.',
                style: AppText.body(fontSize: 12, color: AppColors.roseText),
              ),
            ),
            TextButton(
              onPressed: state.reconnecting ? null : () => state.reconnectServer(),
              child: Text(
                'Retry',
                style: AppText.label(color: AppColors.forest, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _addToPlan(BuildContext context, AppState state) async {
  final plan = state.mealPlan;
  if (plan == null || plan.days.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create a meal plan first, then add these dishes.')),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlannerSetupScreen()),
    );
    return;
  }
  final slots = <PlannedMeal>[
    for (final day in plan.days) ...day.meals,
  ];
  if (slots.isEmpty || !context.mounted) return;
  final picked = await showModalBottomSheet<PlannedMeal>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Add the first shortlisted dish to…', style: AppText.title(fontSize: 18)),
            ),
            for (final meal in slots)
              ListTile(
                title: Text('${meal.date} · ${meal.slot}'),
                subtitle: Text(meal.recipe.title),
                onTap: () => Navigator.pop(ctx, meal),
              ),
          ],
        ),
      );
    },
  );
  if (picked == null || state.shortlist.isEmpty) return;
  await state.placeOnPlan(
    date: picked.date,
    slot: picked.slot,
    recipe: state.shortlist.first,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${state.shortlist.first.title} is on your plan.')),
  );
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final picks = state.shortlist;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleIconButton(
            icon: PhosphorIconsRegular.arrowLeft,
            semanticLabel: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: 16),
          Text(
            picks.isEmpty
                ? 'Nothing shortlisted'
                : '${picks.length} dish${picks.length == 1 ? '' : 'es'} shortlisted',
            style: AppText.h1(),
          ),
          const SizedBox(height: 16),
          if (picks.isEmpty)
            Expanded(
              child: Text(
                'No worries — there’s always another plate.',
                style: AppText.body(),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: picks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final recipe = picks[index];
                  return Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(recipe: recipe),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: RecipePhoto.of(recipe),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                recipe.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.itemTitle(),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove from shortlist',
                              onPressed: () =>
                                  state.removeFromShortlist(recipe.id),
                              icon: const Icon(
                                PhosphorIconsRegular.x,
                                size: 18,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (picks.isNotEmpty) ...[
            PrimaryButton(
              label: 'Add to plan',
              onPressed: () => _addToPlan(context, state),
            ),
            const SizedBox(height: 8),
          ],
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CourseSelectScreen(fromPantry: true),
                ),
              ),
              child: Text(
                'Discover 5 more',
                style: AppText.label(color: AppColors.forest),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
