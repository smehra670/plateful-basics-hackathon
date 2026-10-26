import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/meal_plan.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/ingredient_card.dart';
import 'planner_timetable_screen.dart';

class PlannerPantrySelectScreen extends StatefulWidget {
  const PlannerPantrySelectScreen({
    super.key,
    required this.days,
    required this.meals,
    required this.people,
    required this.goals,
    required this.spice,
    required this.cuisines,
    required this.avoid,
    required this.maxMinutes,
    this.budget,
    this.returnToPlannerTab = false,
    this.closeSetupRoute = false,
  });

  final int days;
  final List<String> meals;
  final int people;
  final List<String> goals;
  final String spice;
  final List<String> cuisines;
  final List<String> avoid;
  final int maxMinutes;
  final double? budget;
  final bool returnToPlannerTab;
  final bool closeSetupRoute;

  @override
  State<PlannerPantrySelectScreen> createState() =>
      _PlannerPantrySelectScreenState();
}

class _PlannerPantrySelectScreenState extends State<PlannerPantrySelectScreen> {
  String _mode = 'all';
  final Set<String> _selected = {};
  bool _prioritise = true;

  Future<void> _generate() async {
    final state = context.read<AppState>();
    final available = state.cookableIngredients;
    final chosen = _mode == 'none'
        ? <PantryIngredient>[]
        : _mode == 'all'
            ? available
            : available.where((i) => _selected.contains(i.id)).toList();

    HapticFeedback.mediumImpact();
    final nav = Navigator.of(context);
    if (widget.returnToPlannerTab) {
      nav.pop();
      if (widget.closeSetupRoute && nav.canPop()) {
        nav.pop();
      }
    } else {
      nav.push(
        MaterialPageRoute(builder: (_) => const PlannerTimetableScreen()),
      );
    }
    await state.generateMealPlan(
      MealPlanRequest(
        durationDays: widget.days,
        meals: widget.meals,
        people: widget.people,
        goals: widget.goals,
        spiceTolerance: widget.spice,
        favouriteCuisines: widget.cuisines,
        avoidIngredients: widget.avoid,
        maxCookMinutes: widget.maxMinutes,
        weeklyBudgetGbp: widget.budget,
        pantryMode: _mode,
        pantry: chosen,
        focusIngredients: _prioritise
            ? chosen.map((e) => e.name).toList()
            : const [],
        preferences: state.preferences.toRecipePayload(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.cookableIngredients;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('Pantry for this plan', style: AppText.title(fontSize: 18)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose exactly which ingredients the AI may use. Unselected items stay out of this plan.',
                  style: AppText.body(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _modeChip('all', 'Entire pantry'),
                    _modeChip('selected', 'Select specific'),
                    _modeChip('none', 'No pantry'),
                  ],
                ),
                if (_mode == 'selected') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(
                          () => _selected.addAll(items.map((e) => e.id)),
                        ),
                        child: const Text('Select all'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selected.clear()),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Prioritise these ingredients',
                      style: AppText.label(),
                    ),
                    value: _prioritise,
                    activeThumbColor: AppColors.green,
                    onChanged: (v) => setState(() => _prioritise = v),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _mode != 'selected'
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        _mode == 'all'
                            ? 'The whole pantry will be available stock for this plan.'
                            : 'Recipes will assume a shop, with no pantry stock allocated.',
                        textAlign: TextAlign.center,
                        style: AppText.body(),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IngredientCard(
                          ingredient: item,
                          selected: _selected.contains(item.id),
                          soonDays: state.expirySoonDays,
                          onTap: () => setState(() {
                            if (_selected.contains(item.id)) {
                              _selected.remove(item.id);
                            } else {
                              _selected.add(item.id);
                            }
                          }),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _mode == 'selected' && _selected.isEmpty
                    ? null
                    : _generate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
                child: Text('Generate plan', style: AppText.button()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String id, String label) {
    final on = _mode == id;
    return ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => setState(() => _mode = id),
      selectedColor: AppColors.sageMuted,
    );
  }
}
