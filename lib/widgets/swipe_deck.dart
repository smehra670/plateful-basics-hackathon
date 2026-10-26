import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/pressable.dart';
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
    this.expiringCount,
  });

  final List<Recipe> recipes;
  final Set<String> savedIds;
  final int currentIndex;
  final VoidCallback onLike;
  final VoidCallback onReject;
  final VoidCallback onUndo;
  final ValueChanged<Recipe> onHeart;
  final int Function(Recipe recipe)? expiringCount;

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

  Recipe? get _current {
    final index = widget.currentIndex;
    if (index < 0 || index >= widget.recipes.length) return null;
    return widget.recipes[index];
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.currentIndex.clamp(0, widget.recipes.length);
    final remaining = widget.recipes.length - progress;
    final current = _current;
    final saved = current != null && widget.savedIds.contains(current.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
      child: Column(
        children: [
          Row(
            children: [
              CircleIconButton(
                icon: PhosphorIconsRegular.arrowLeft,
                semanticLabel: 'Back',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Column(
                  children: [
                    _ProgressBar(
                      total: widget.recipes.length,
                      current: progress,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${progress + 1} of ${widget.recipes.length} ideas',
                      style: AppText.caption(fontSize: 13),
                    ),
                  ],
                ),
              ),
              CircleIconButton(
                icon: saved
                    ? PhosphorIconsFill.heart
                    : PhosphorIconsRegular.heart,
                iconColor: AppColors.roseText,
                semanticLabel: 'Save forever',
                onTap: current == null ? null : () => widget.onHeart(current),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: remaining <= 0
                ? const SizedBox.shrink()
                : Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      if (remaining > 1)
                        const Positioned(
                          left: 18,
                          right: 18,
                          bottom: 0,
                          top: 18,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.deckPeek,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(30),
                                top: Radius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.only(bottom: remaining > 1 ? 10 : 0),
                        child: CardSwiper(
                          controller: _controller,
                          cardsCount: widget.recipes.length,
                          initialIndex: widget.currentIndex.clamp(
                            0,
                            widget.recipes.length - 1,
                          ),
                          numberOfCardsDisplayed: 1,
                          isLoop: false,
                          maxAngle: 8,
                          padding: EdgeInsets.zero,
                          allowedSwipeDirection: const AllowedSwipeDirection.only(
                            left: true,
                            right: true,
                          ),
                          onSwipe: (prev, currentIndex, direction) {
                            if (direction == CardSwiperDirection.right) {
                              widget.onLike();
                            } else if (direction == CardSwiperDirection.left) {
                              widget.onReject();
                            }
                            return true;
                          },
                          cardBuilder: (context, index, percentX, percentY) {
                            final recipe = widget.recipes[index];
                            final like = (percentX / 100).clamp(0.0, 1.0);
                            final skip = (-percentX / 100).clamp(0.0, 1.0);
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                RecipeCard(
                                  recipe: recipe,
                                  expiringCount:
                                      widget.expiringCount?.call(recipe) ?? 0,
                                  onMissingTap: () =>
                                      showMissingIngredientsSheet(context, recipe),
                                ),
                                if (like > 0.08)
                                  Positioned(
                                    top: 28,
                                    left: 18,
                                    child: Opacity(
                                      opacity: like,
                                      child: const _SwipeStamp(
                                        label: 'SHORTLIST',
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  ),
                                if (skip > 0.08)
                                  Positioned(
                                    top: 28,
                                    right: 18,
                                    child: Opacity(
                                      opacity: skip,
                                      child: const _SwipeStamp(
                                        label: 'SKIP',
                                        color: AppColors.roseText,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                size: 64,
                background: AppColors.surface,
                icon: PhosphorIconsRegular.x,
                iconColor: AppColors.roseText,
                semanticLabel: 'Skip',
                shadow: AppShadows.chip,
                onTap: () => _controller.swipe(CardSwiperDirection.left),
              ),
              const SizedBox(width: 22),
              _ActionButton(
                size: 48,
                background: AppColors.surface,
                icon: PhosphorIconsRegular.arrowCounterClockwise,
                iconColor: AppColors.muted,
                semanticLabel: 'Undo',
                shadow: AppShadows.chip,
                onTap: () {
                  widget.onUndo();
                  _controller.undo();
                },
              ),
              const SizedBox(width: 22),
              _ActionButton(
                size: 64,
                background: AppColors.forest,
                icon: PhosphorIconsRegular.check,
                iconColor: Colors.white,
                semanticLabel: 'Shortlist',
                shadow: AppShadows.primaryGlow,
                onTap: () => _controller.swipe(CardSwiperDirection.right),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Swipe right to shortlist · heart to keep forever',
            textAlign: TextAlign.center,
            style: AppText.caption(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final count = total <= 0 ? 1 : total;
    return SizedBox(
      width: 130,
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= current ? AppColors.forest : AppColors.sageTrack,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: label == 'SKIP' ? 0.12 : -0.12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppText.caption(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ).copyWith(letterSpacing: 0.6),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.size,
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.semanticLabel,
    required this.shadow,
    required this.onTap,
  });

  final double size;
  final Color background;
  final IconData icon;
  final Color iconColor;
  final String semanticLabel;
  final List<BoxShadow> shadow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: semanticLabel,
      onTap: onTap,
      child: Tooltip(
        message: semanticLabel,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: shadow,
          ),
          child: Icon(icon, color: iconColor, size: size > 56 ? 26 : 20),
        ),
      ),
    );
  }
}
