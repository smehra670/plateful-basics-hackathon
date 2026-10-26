import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../models/meal_plan.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/food_facts.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/pantry_chip.dart';
import '../widgets/pressable.dart';
import '../widgets/profile_avatar_button.dart';
import '../widgets/quantity_label.dart';
import '../widgets/recipe_photo.dart';
import '../widgets/rule_pill.dart';
import '../widgets/skeleton.dart';
import '../widgets/staggered_entrance.dart';
import 'course_select_screen.dart';
import 'planner_setup_screen.dart';
import 'recipe_detail_screen.dart';

class PlannerTimetableScreen extends StatefulWidget {
  const PlannerTimetableScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PlannerTimetableScreen> createState() => _PlannerTimetableScreenState();
}

class _PlannerTimetableScreenState extends State<PlannerTimetableScreen> {
  int _dayIndex = 0;
  bool _weekView = false;
  String? _completingKey;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final plan = state.mealPlan;
    final bottom = widget.embedded ? kFloatingNavClearance : 28.0;

    return Scaffold(
      backgroundColor: AppColors.ground,
      primary: !widget.embedded,
      body: SafeArea(
        bottom: !widget.embedded,
        child: state.plannerLoading && plan == null
            ? const RecipeLoadingView(forPlanner: true)
            : plan == null
                ? _empty(state)
                : Column(
                    children: [
                      if (state.plannerLoading)
                        const LinearProgressIndicator(
                          color: AppColors.forest,
                          backgroundColor: AppColors.sageTrack,
                        ),
                      if (state.plannerError != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Text(
                            state.plannerError!,
                            style: AppText.body(color: AppColors.roseText),
                          ),
                        ),
                      Expanded(
                        child: _weekView
                            ? _weekOverview(plan, bottom)
                            : _dayView(plan, bottom),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _empty(AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          state.plannerError ??
              'No plan yet. Go back and generate one from your pantry.',
          textAlign: TextAlign.center,
          style: AppText.body(),
        ),
      ),
    );
  }

  Widget _dayView(MealPlan plan, double bottom) {
    final index = _dayIndex.clamp(0, plan.days.length - 1);
    final day = plan.days[index];
    final date = DateTime.tryParse(day.date) ?? DateTime.now();

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 12, 0, bottom),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _header(date),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _toolRow(),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _dayStrip(plan),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _NutritionCard(meals: day.meals, date: day.date),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: day.meals.isEmpty
              ? Text('No meals on this day.', style: AppText.body())
              : Column(
                  children: [
                    for (var i = 0; i < day.meals.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, thickness: 1, color: AppColors.line),
                      StaggeredEntrance(
                        index: i,
                        child: _mealRow(day.meals[i]),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _pantryHeader(plan),
        ),
        const SizedBox(height: 12),
        _pantryChips(plan),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _shoppingCard(plan),
        ),
      ],
    );
  }

  Widget _header(DateTime date) {
    final overline = DateFormat('EEEE · d MMM').format(date).toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!widget.embedded) ...[
          CircleIconButton(
            icon: PhosphorIconsRegular.arrowLeft,
            semanticLabel: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.overline(),
              ),
              Text(
                'Your plan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.h1(),
              ),
            ],
          ),
        ),
        const ProfileAvatarButton(),
      ],
    );
  }

  Widget _toolRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleIconButton(
          icon: _weekView
              ? PhosphorIconsRegular.list
              : PhosphorIconsRegular.calendarBlank,
          semanticLabel: _weekView ? 'Daily view' : 'Week view',
          onTap: () => setState(() => _weekView = !_weekView),
        ),
        const SizedBox(width: 8),
        CircleIconButton(
          icon: PhosphorIconsRegular.plus,
          semanticLabel: 'New plan',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlannerSetupScreen()),
            );
          },
        ),
      ],
    );
  }

  List<int> _mondayFirst(MealPlan plan) {
    final indexes = List<int>.generate(plan.days.length, (i) => i);
    indexes.sort((a, b) {
      final da = DateTime.tryParse(plan.days[a].date) ?? DateTime.now();
      final db = DateTime.tryParse(plan.days[b].date) ?? DateTime.now();
      final byWeekday = da.weekday.compareTo(db.weekday);
      if (byWeekday != 0) return byWeekday;
      return da.compareTo(db);
    });
    return indexes;
  }

  Widget _dayStrip(MealPlan plan) {
    final order = _mondayFirst(plan);
    if (order.length > 7) {
      return SizedBox(
        height: 64,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: order.length,
          itemBuilder: (context, i) => SizedBox(
            width: 44,
            child: _dayColumn(plan, order[i]),
          ),
        ),
      );
    }
    return Row(
      children: [
        for (final i in order) Expanded(child: _dayColumn(plan, i)),
      ],
    );
  }

  Widget _dayColumn(MealPlan plan, int i) {
    final date = DateTime.tryParse(plan.days[i].date) ?? DateTime.now();
    final selected = i == _dayIndex;
    final letter = DateFormat('E').format(date).characters.first;
    return Pressable(
      semanticLabel: DateFormat('EEEE d').format(date),
      selected: selected,
      onTap: () => setState(() {
        _dayIndex = i;
        _weekView = false;
      }),
      child: Column(
        children: [
          Text(
            letter,
            maxLines: 1,
            style: AppText.caption(
              fontSize: 12,
              color: selected ? AppColors.forest : AppColors.muted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.forest : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              DateFormat.d().format(date),
              style: AppText.label(
                fontSize: 15,
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _DayProgress(
            done: plan.days[i].meals.where((m) => m.completed).length,
            total: plan.days[i].meals.length,
          ),
        ],
      ),
    );
  }

  Widget _mealRow(PlannedMeal meal) {
    final recipe = meal.recipe;
    final completing = _completingKey == meal.planKey;
    final eaten = meal.completed;
    return Pressable(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(
              recipe: recipe,
              planDate: meal.date,
              planSlot: meal.slot,
            ),
          ),
        );
      },
      child: GestureDetector(
        onLongPress: () => _openMealSheet(meal),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: RecipePhoto(url: recipe.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_slotLabel(meal.slot)} · ${recipe.cookingTimeMinutes} min',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.itemTitle(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      eaten
                          ? '${recipe.calories} kcal · eaten'
                          : '${recipe.calories} kcal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption(
                        color: eaten ? AppColors.forest : AppColors.muted,
                        fontWeight: eaten ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _EatenToggle(
                eaten: eaten,
                busy: completing,
                semanticLabel: eaten
                    ? '${_slotLabel(meal.slot)} eaten'
                    : 'Mark ${_slotLabel(meal.slot).toLowerCase()} as eaten',
                onTap: eaten || completing
                    ? null
                    : () {
                        final blocked =
                            context.read<AppState>().cookBlockReason(recipe);
                        if (blocked != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(blocked)),
                          );
                          return;
                        }
                        _complete(meal);
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pantryHeader(MealPlan plan) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'In your pantry',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.section(),
          ),
        ),
        Pressable(
          semanticLabel: 'Cook with these',
          onTap: () => _cookWithPantry(plan),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cook with these',
                style: AppText.label(color: AppColors.forest, fontSize: 14),
              ),
              const SizedBox(width: 4),
              const Icon(
                PhosphorIconsRegular.arrowRight,
                size: 16,
                color: AppColors.forest,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pantryChips(MealPlan plan) {
    if (plan.pantryUsage.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Text(
          'No pantry stock allocated yet.',
          style: AppText.body(fontSize: 13),
        ),
      );
    }
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: plan.pantryUsage.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = plan.pantryUsage[i];
          return PantryChip(
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
          );
        },
      ),
    );
  }

  double _shoppingCost(MealPlan plan, ShoppingItem item) {
    final key = item.name.trim().toLowerCase();
    var cost = 0.0;
    for (final day in plan.days) {
      for (final meal in day.meals) {
        for (final ingredient in meal.recipe.ingredients) {
          if (ingredient.inPantry) continue;
          if (ingredient.name.trim().toLowerCase() != key) continue;
          cost += ingredient.estimatedCostGbp;
        }
      }
    }
    return cost;
  }

  Widget _shoppingCard(MealPlan plan) {
    final open = plan.shoppingList.where((item) => !item.checked).toList();
    final total = open.fold<double>(
      0,
      (sum, item) => sum + _shoppingCost(plan, item),
    );
    final groups = <String, List<ShoppingItem>>{};
    for (final item in plan.shoppingList) {
      final aisle = FoodFacts.aisle(item.name);
      groups.putIfAbsent(aisle, () => []).add(item);
    }
    const order = [
      'Fruit & veg',
      'Dairy',
      'Meat & fish',
      'Bakery',
      'Cupboard',
    ];
    final aisles = [
      ...order.where(groups.containsKey),
      ...groups.keys.where((key) => !order.contains(key)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shopping list', style: AppText.section()),
        const SizedBox(height: 4),
        Text(
          plan.shoppingList.isEmpty
              ? 'Nothing extra to buy.'
              : '${open.length} items · ~£${total.toStringAsFixed(2)}',
          style: AppText.body(fontSize: 13),
        ),
        const SizedBox(height: 8),
        for (final aisle in aisles) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(aisle, style: AppText.caption()),
          ),
          for (final item in groups[aisle]!)
            _shoppingRow(item, _shoppingCost(plan, item)),
        ],
      ],
    );
  }

  Widget _shoppingRow(ShoppingItem item, double cost) {
    final tone = _priceTone(cost);
    return InkWell(
      onTap: () => context.read<AppState>().toggleShoppingItem(item.name),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            item.checked
                ? PhosphorIconsFill.checkSquare
                : PhosphorIconsRegular.square,
            size: 20,
            color: item.checked ? AppColors.forest : AppColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.itemTitle(fontWeight: FontWeight.w500).copyWith(
                decoration:
                    item.checked ? TextDecoration.lineThrough : null,
                color: item.checked ? AppColors.muted : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatQuantity(item.quantity)} ${item.unit}',
                style: AppText.caption(fontWeight: FontWeight.w500),
              ),
              if (cost > 0)
                Text(
                  '£${cost.toStringAsFixed(2)}',
                  style: AppText.caption(
                    color: tone,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Color _priceTone(double gbp) {
    if (gbp <= 0) return AppColors.ringBorder;
    if (gbp < 0.75) return AppColors.forest;
    if (gbp < 2) return AppColors.skyText;
    return AppColors.peachText;
  }

  Widget _weekOverview(MealPlan plan, double bottom) {
    final date = DateTime.tryParse(
          plan.days[_dayIndex.clamp(0, plan.days.length - 1)].date,
        ) ??
        DateTime.now();
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
      children: [
        _header(date),
        const SizedBox(height: 12),
        _toolRow(),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _mondayFirst(plan).length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, visual) {
            final i = _mondayFirst(plan)[visual];
            final day = plan.days[i];
            final parsed = DateTime.tryParse(day.date) ?? DateTime.now();
            return Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() {
                  _dayIndex = i;
                  _weekView = false;
                }),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('E d').format(parsed),
                        style: AppText.label(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      for (final meal in day.meals)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: RecipePhoto(url: meal.recipe.imageUrl),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  meal.recipe.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.caption(
                                    color: meal.completed
                                        ? AppColors.forest
                                        : AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _cookWithPantry(MealPlan plan) {
    final names = plan.pantryUsage.map((item) => item.name).toList();
    final focus = names.isNotEmpty
        ? names
        : context.read<AppState>().cookableIngredients.map((i) => i.name).toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseSelectScreen(
          fromPantry: true,
          focusIngredients: focus,
        ),
      ),
    );
  }

  Future<void> _openMealSheet(PlannedMeal meal) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                title: const Text('Swap meal'),
                onTap: () => Navigator.pop(ctx, 'swap'),
              ),
              ListTile(
                title: const Text('Use a saved recipe'),
                onTap: () => Navigator.pop(ctx, 'saved'),
              ),
              ListTile(
                title: const Text('Refresh image'),
                onTap: () => Navigator.pop(ctx, 'image'),
              ),
              ListTile(
                title: const Text('Remove'),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            ],
          ),
        );
      },
    );
    if (value == null || !mounted) return;
    await _onMenu(value, meal);
  }

  String _slotLabel(String slot) {
    if (slot.isEmpty) return slot;
    return slot[0].toUpperCase() + slot.substring(1);
  }

  Future<void> _complete(PlannedMeal meal) async {
    setState(() => _completingKey = meal.planKey);
    try {
      await context.read<AppState>().completePlannedMeal(meal);
      if (!mounted) return;
      final flash = context.read<AppState>().lastRescueFlash;
      final message = flash == null
          ? '${meal.recipe.title} marked as eaten'
          : 'You just kept ${flash.rescuedKg.toStringAsFixed(2)} kg of ${flash.highlightFood.toLowerCase()} out of the bin';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _completingKey = null);
    }
  }

  Future<void> _onMenu(String value, PlannedMeal meal) async {
    final state = context.read<AppState>();
    switch (value) {
      case 'swap':
        await state.swapPlannedMeal(date: meal.date, slot: meal.slot);
      case 'image':
        await state.refreshPlannedImage(date: meal.date, slot: meal.slot);
      case 'remove':
        await state.removePlannedMeal(date: meal.date, slot: meal.slot);
      case 'saved':
        if (!mounted) return;
        final picked = await showModalBottomSheet<Recipe>(
          context: context,
          backgroundColor: AppColors.surface,
          builder: (ctx) {
            if (state.savedRecipes.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No saved recipes yet.'),
              );
            }
            return ListView(
              children: state.savedRecipes
                  .map(
                    (r) => ListTile(
                      title: Text(r.title),
                      onTap: () => Navigator.pop(ctx, r),
                    ),
                  )
                  .toList(),
            );
          },
        );
        if (picked == null) return;
        await state.replacePlannedMealWithSaved(
          date: meal.date,
          slot: meal.slot,
          recipe: picked,
        );
    }
  }
}

class _MacroSlide {
  const _MacroSlide({
    required this.label,
    required this.shortLabel,
    required this.unit,
    required this.eaten,
    required this.planned,
    required this.accent,
    required this.wash,
    this.whole = false,
    required this.amount,
  });

  final String label;
  final String shortLabel;
  final String unit;
  final double eaten;
  final double planned;
  final Color accent;
  final Color wash;
  final bool whole;
  final double Function(EatenLogEntry entry) amount;
}

class _NutritionCard extends StatefulWidget {
  const _NutritionCard({required this.meals, required this.date});

  final List<PlannedMeal> meals;
  final String date;

  @override
  State<_NutritionCard> createState() => _NutritionCardState();
}

class _NutritionCardState extends State<_NutritionCard> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _planned(double Function(Recipe recipe) pick) {
    return widget.meals.fold(0, (sum, meal) => sum + pick(meal.recipe));
  }

  double _eatenAmount(List<EatenLogEntry> entries, double Function(EatenLogEntry entry) pick) {
    return entries.fold(0, (sum, entry) => sum + pick(entry));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final planId = state.mealPlan?.id ?? '';
    final entries = state.eatenLog.where((entry) {
      if (planId.isEmpty) return entry.countsOn(widget.date);
      return entry.planKey?.startsWith('$planId|${widget.date}|') ?? false;
    }).toList();
    final slides = <_MacroSlide>[
      _MacroSlide(
        label: 'Calories eaten',
        shortLabel: 'kcal',
        unit: 'kcal',
        eaten: _eatenAmount(entries, (entry) => entry.calories.toDouble()),
        planned: _planned((recipe) => recipe.calories.toDouble()),
        accent: AppColors.forest,
        wash: AppColors.sageSoft,
        whole: true,
        amount: (entry) => entry.calories.toDouble(),
      ),
      _MacroSlide(
        label: 'Protein eaten',
        shortLabel: 'protein',
        unit: 'g',
        eaten: _eatenAmount(entries, (entry) => entry.protein),
        planned: _planned((recipe) => recipe.protein),
        accent: AppColors.proteinText,
        wash: AppColors.peachSoft,
        amount: (entry) => entry.protein,
      ),
      _MacroSlide(
        label: 'Carbs eaten',
        shortLabel: 'carbs',
        unit: 'g',
        eaten: _eatenAmount(entries, (entry) => entry.carbohydrates),
        planned: _planned((recipe) => recipe.carbohydrates),
        accent: AppColors.carbsText,
        wash: AppColors.carbsSoft,
        amount: (entry) => entry.carbohydrates,
      ),
      _MacroSlide(
        label: 'Fat eaten',
        shortLabel: 'fat',
        unit: 'g',
        eaten: _eatenAmount(entries, (entry) => entry.fat),
        planned: _planned((recipe) => recipe.fat),
        accent: AppColors.fatText,
        wash: AppColors.skySoft,
        amount: (entry) => entry.fat,
      ),
      _MacroSlide(
        label: 'Fibre eaten',
        shortLabel: 'fibre',
        unit: 'g',
        eaten: _eatenAmount(entries, (entry) => entry.fibre),
        planned: _planned((recipe) => recipe.fibre),
        accent: AppColors.fibreText,
        wash: AppColors.fibreSoft,
        amount: (entry) => entry.fibre,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1B2A22),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 124,
            child: PageView.builder(
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                return _macroSlide(
                  slides[index],
                  entries,
                  index,
                  slides.length,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < slides.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        slides[i].shortLabel,
                        textAlign: TextAlign.center,
                        style: AppText.caption(
                          color: i == _index ? slides[i].accent : AppColors.muted,
                          fontWeight:
                              i == _index ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const AccountRulePills(),
        ],
      ),
    );
  }

  Widget _macroSlide(
    _MacroSlide slide,
    List<EatenLogEntry> entries,
    int page,
    int pageCount,
  ) {
    final progress = slide.planned <= 0
        ? 0.0
        : (slide.eaten / slide.planned).clamp(0.0, 1.0);
    final eatenLabel = slide.whole
        ? NumberFormat.decimalPattern().format(slide.eaten.round())
        : slide.eaten.toStringAsFixed(0);
    final plannedLabel = slide.whole
        ? NumberFormat.decimalPattern().format(slide.planned.round())
        : slide.planned.toStringAsFixed(0);
    return GestureDetector(
      onTap: () => _showSources(slide, entries),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.label,
                      style: AppText.caption(
                        color: slide.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(eatenLabel, style: AppText.stat(color: slide.accent)),
                    Text(
                      'of $plannedLabel ${slide.unit}',
                      style: AppText.body(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: slide.wash,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '${page + 1} of $pageCount',
                  style: AppText.caption(
                    color: slide.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: slide.wash,
                color: slide.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSources(_MacroSlide slide, List<EatenLogEntry> entries) {
    final rows = entries.where((entry) => slide.amount(entry) > 0).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slide.label, style: AppText.section(color: slide.accent)),
                const SizedBox(height: 4),
                Text(
                  'Where it came from',
                  style: AppText.caption(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Nothing eaten for this day yet.',
                      style: AppText.body(),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: rows.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.line),
                      itemBuilder: (context, index) {
                        final entry = rows[index];
                        final amount = slide.amount(entry);
                        final amountLabel = slide.whole
                            ? '${amount.round()} ${slide.unit}'
                            : '${amount.toStringAsFixed(0)} ${slide.unit}';
                        final when = DateFormat('d MMM · h:mm a')
                            .format(entry.timestamp.toLocal());
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.itemTitle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(when, style: AppText.caption()),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                amountLabel,
                                style: AppText.label(color: slide.accent),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EatenToggle extends StatefulWidget {
  const _EatenToggle({
    required this.eaten,
    required this.busy,
    required this.semanticLabel,
    required this.onTap,
  });

  final bool eaten;
  final bool busy;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  State<_EatenToggle> createState() => _EatenToggleState();
}

class _EatenToggleState extends State<_EatenToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.eaten ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _EatenToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.eaten && widget.eaten) {
      _bounce.forward(from: 0);
    } else if (!widget.eaten) {
      _bounce.value = 0;
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _bounce, curve: Curves.elasticOut),
    );
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      toggled: widget.eaten,
      child: Tooltip(
        message: widget.semanticLabel,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.eaten ? AppColors.forest : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.eaten ? AppColors.surface : AppColors.ringBorder,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x141B2A22),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: widget.busy
                ? const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: AppColors.forest,
                    ),
                  )
                : widget.eaten
                    ? ScaleTransition(
                        scale: scale,
                        child: const Icon(
                          PhosphorIconsRegular.check,
                          color: Colors.white,
                          size: 22,
                        ),
                      )
                    : null,
            ),
        ),
      ),
    );
  }
}

class _DayProgress extends StatelessWidget {
  const _DayProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : done / total;
    return SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(
        value: frac == 0 ? 0.001 : frac,
        strokeWidth: 2.2,
        backgroundColor: AppColors.line,
        color: frac >= 1 ? AppColors.forest : AppColors.peachText,
      ),
    );
  }
}
