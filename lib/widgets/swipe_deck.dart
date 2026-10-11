import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'recipe_card.dart';

class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.recipes,
    required this.savedIds,
    required this.currentIndex,
    required this.onLike,
    required this.onReject,
    required this.onUndo,
    required this.onHeart,
  });

  final List<Recipe> recipes;
  final Set<String> savedIds;
  final int currentIndex;
  final VoidCallback onLike;
  final VoidCallback onReject;
  final VoidCallback onUndo;
  final ValueChanged<Recipe> onHeart;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.currentIndex.clamp(0, widget.recipes.length);
    final remaining = widget.recipes.length - progress;

    return Column(
      children: [
        Text(
          '${progress + 1} / ${widget.recipes.length}',
          style: AppText.label(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: remaining <= 0
              ? const SizedBox.shrink()
              : CardSwiper(
                  controller: _controller,
                  cardsCount: widget.recipes.length,
                  numberOfCardsDisplayed: remaining.clamp(1, 2),
                  isLoop: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onSwipe: (prev, current, direction) {
                    HapticFeedback.selectionClick();
                    if (direction == CardSwiperDirection.right) {
                      widget.onLike();
                    } else {
                      widget.onReject();
                    }
                    return true;
                  },
                  cardBuilder: (context, index, percentX, percentY) {
                    final recipe = widget.recipes[index];
                    return RecipeCard(
                      recipe: recipe,
                      isSaved: widget.savedIds.contains(recipe.id),
                      onHeart: () => widget.onHeart(recipe),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundAction(
              icon: Icons.close_rounded,
              color: AppColors.error,
              onTap: () {
                HapticFeedback.mediumImpact();
                _controller.swipe(CardSwiperDirection.left);
              },
            ),
            const SizedBox(width: 20),
            _RoundAction(
              icon: Icons.undo_rounded,
              color: AppColors.textSecondary,
              small: true,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onUndo();
                _controller.undo();
              },
            ),
            const SizedBox(width: 20),
            _RoundAction(
              icon: Icons.favorite_rounded,
              color: AppColors.green,
              onTap: () {
                HapticFeedback.mediumImpact();
                _controller.swipe(CardSwiperDirection.right);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Swipe right to shortlist · Heart to save forever',
          style: AppText.body(fontSize: 12),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.small = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 48.0 : 64.0;
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: color, size: small ? 22 : 28),
        ),
      ),
    );
  }
}
