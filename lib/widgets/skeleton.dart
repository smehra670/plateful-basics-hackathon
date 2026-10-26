import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.45 + (_controller.value * 0.4),
          child: child,
        );
      },
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.creamDark,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class RecipeSkeleton extends StatelessWidget {
  const RecipeSkeleton({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return RecipeLoadingView(message: message);
  }
}

enum LoadKind { recipes, planner, pantry }

class RecipeLoadingView extends StatefulWidget {
  const RecipeLoadingView({
    super.key,
    this.kind = LoadKind.recipes,
    this.forPlanner = false,
    this.message,
  });

  final LoadKind kind;
  final bool forPlanner;
  final String? message;

  @override
  State<RecipeLoadingView> createState() => _RecipeLoadingViewState();
}

class _RecipeLoadingViewState extends State<RecipeLoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _travel;
  int _stage = 0;

  LoadKind get _kind =>
      widget.forPlanner ? LoadKind.planner : widget.kind;

  List<String> get _stages => switch (_kind) {
        LoadKind.planner => const [
            'Reading your pantry',
            'Balancing the week',
            'Writing each meal',
            'Almost plated',
          ],
        LoadKind.pantry => const [
            'Looking at your photo',
            'Finding each food',
            'Adding them to the pantry',
          ],
        LoadKind.recipes => const [
            'Tasting your ingredients',
            'Drafting the dishes',
            'Finishing the recipes',
          ],
      };

  @override
  void initState() {
    super.initState();
    _travel = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return false;
      setState(() => _stage = (_stage + 1) % _stages.length);
      return true;
    });
  }

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.message ?? _stages[_stage];
    final card = _kind == LoadKind.recipes;
    return ColoredBox(
      color: AppColors.ground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (card)
                Container(
                  height: 420,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppShadows.heroCard,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(height: 180, radius: 20),
                      SizedBox(height: 16),
                      SkeletonBox(height: 28, width: 220),
                      SizedBox(height: 10),
                      SkeletonBox(height: 14),
                      SizedBox(height: 8),
                      SkeletonBox(height: 14, width: 180),
                      Spacer(),
                      SkeletonBox(height: 48, radius: 14),
                    ],
                  ),
                ),
              if (card) const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: Text(
                  label,
                  key: ValueKey(label),
                  textAlign: TextAlign.center,
                  style: AppText.caption(
                    color: AppColors.forest,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _travel,
                builder: (context, _) => _QuietBar(travel: _travel.value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietBar extends StatelessWidget {
  const _QuietBar({required this.travel});

  final double travel;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeInOut.transform(travel);
    return Semantics(
      label: 'Loading',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          width: 148,
          height: 3,
          child: ColoredBox(
            color: AppColors.sageTrack,
            child: Align(
              alignment: Alignment(-1 + eased * 2, 0),
              child: Container(
                width: 52,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
