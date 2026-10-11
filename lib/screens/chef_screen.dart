import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/profile_avatar_button.dart';
import '../widgets/recipe_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/swipe_deck.dart';
import 'recipe_detail_screen.dart';

class ChefScreen extends StatelessWidget {
  const ChefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plateful', style: AppText.display(fontSize: 28)),
                      Text(
                        state.usingDemoPipeline
                            ? 'Demo mode · Make more. Waste less.'
                            : 'Let\'s make something delicious.',
                        style: AppText.body(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const ProfileAvatarButton(),
              ],
            ),
          ),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppState state) {
    switch (state.chefPhase) {
      case ChefPhase.loading:
        return const RecipeSkeleton();
      case ChefPhase.swiping:
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: SwipeDeck(
            key: ValueKey(state.deck.map((r) => r.id).join('|')),
            recipes: state.deck,
            savedIds: state.savedIds,
            currentIndex: state.swipeIndex,
            onLike: state.likeCurrent,
            onReject: state.rejectCurrent,
            onUndo: state.undoSwipe,
            onHeart: state.toggleSave,
          ),
        );
      case ChefPhase.results:
        return _ResultsView(state: state);
      case ChefPhase.idle:
        return _IdleView(state: state);
    }
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.sageMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 40,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your next meal starts here.',
            textAlign: TextAlign.center,
            style: AppText.display(fontSize: 26),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan what\'s in your kitchen, or cook with ingredients already in your pantry.',
            textAlign: TextAlign.center,
            style: AppText.body(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => state.setShellTab(1),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text('What\'s in your kitchen?', style: AppText.button()),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: state.availableIngredients.isEmpty
                  ? null
                  : () => state.generateRecipesFromPantry(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Cook with my pantry',
                style: AppText.button(color: AppColors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final picks = state.shortlist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            picks.isEmpty ? 'Nothing caught your eye?' : 'Your picks.',
            style: AppText.display(fontSize: 28),
          ),
        ),
        if (picks.isEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No worries — there\'s always another plate.',
                    textAlign: TextAlign.center,
                    style: AppText.body(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => state.generateRecipesFromPantry(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text('Discover 5 more', style: AppText.button()),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: picks.length,
              itemBuilder: (context, index) {
                final recipe = picks[index];
                return RecipeGridCard(
                  recipe: recipe,
                  isSaved: state.savedIds.contains(recipe.id),
                  onHeart: () => state.toggleSave(recipe),
                  onRemove: () => state.removeFromShortlist(recipe.id),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        if (picks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => state.generateRecipesFromPantry(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Discover 5 more',
                  style: AppText.button(color: AppColors.green),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
