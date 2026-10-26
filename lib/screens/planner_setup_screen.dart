import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user_preferences.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'planner_pantry_select_screen.dart';
import 'planner_timetable_screen.dart';

class PlannerSetupScreen extends StatefulWidget {
  const PlannerSetupScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PlannerSetupScreen> createState() => _PlannerSetupScreenState();
}

class _PlannerSetupScreenState extends State<PlannerSetupScreen> {
  int _days = 7;
  final Set<String> _meals = {'breakfast', 'lunch', 'dinner'};
  int _people = 2;
  final Set<String> _goals = {'Balanced'};
  String _spice = 'Medium';
  final Set<String> _cuisines = {};
  final List<String> _avoid = [];
  int _maxMinutes = 30;
  final _budgetCtrl = TextEditingController();
  final _avoidCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prefs = context.read<AppState>().preferences;
    _people = prefs.householdSize;
    _spice = prefs.spiceTolerance;
    _cuisines.addAll(prefs.favouriteCuisines);
    _avoid.addAll(prefs.avoidIngredients);
    _maxMinutes = prefs.maxCookMinutes;
    if (prefs.mealGoal.isNotEmpty) {
      _goals
        ..clear()
        ..add(prefs.mealGoal);
    }
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _avoidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppState>().preferences;
    final hasPlan = context.watch<AppState>().mealPlan != null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        automaticallyImplyLeading: !widget.embedded,
        title: Text(
          widget.embedded ? 'New meal plan' : 'Meal planner',
          style: AppText.title(fontSize: 18),
        ),
        actions: [
          if (hasPlan && !widget.embedded)
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PlannerTimetableScreen(),
                  ),
                );
              },
              child: const Text('Open plan'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Choose how you eat this week. Then pick pantry stock and we build the plan.',
            style: AppText.body(),
          ),
          if (prefs.allergies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.peachSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Allergies from your account: ${prefs.allergies.join(', ')}. These stay excluded.',
                style: AppText.label(fontSize: 12, color: AppColors.accent),
              ),
            ),
          ],
          _label('Duration'),
          _chips(
            ['3 days', '5 days', '7 days'],
            ['$_days days'],
            (v) => setState(() => _days = int.parse(v.split(' ').first)),
            single: true,
          ),
          _label('Meals to include'),
          _chips(
            const ['breakfast', 'lunch', 'dinner', 'snack'],
            _meals.toList(),
            (v) => setState(() {
              if (_meals.contains(v) && _meals.length > 1) {
                _meals.remove(v);
              } else {
                _meals.add(v);
              }
            }),
          ),
          _label('People'),
          Row(
            children: [
              IconButton(
                onPressed: _people > 1
                    ? () => setState(() => _people -= 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_people', style: AppText.title()),
              IconButton(
                onPressed: _people < 8
                    ? () => setState(() => _people += 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          _label('Goals'),
          _chips(
            [
              ...UserPreferences.goalOptions,
              'Low calorie',
              'Quick meals',
            ],
            _goals.toList(),
            (v) => setState(() {
              if (_goals.contains(v)) {
                _goals.remove(v);
              } else {
                if (v == 'Weight gain') _goals.remove('Weight loss');
                if (v == 'Weight loss') _goals.remove('Weight gain');
                _goals.add(v);
              }
            }),
          ),
          _label('Spice'),
          _chips(
            UserPreferences.spiceOptions,
            [_spice],
            (v) => setState(() => _spice = v),
            single: true,
          ),
          _label('Favourite cuisines'),
          _chips(
            UserPreferences.cuisineOptions,
            _cuisines.toList(),
            (v) => setState(() {
              if (_cuisines.contains(v)) {
                _cuisines.remove(v);
              } else {
                _cuisines.add(v);
              }
            }),
          ),
          _label('Disliked ingredients'),
          Wrap(
            spacing: 8,
            children: _avoid
                .map(
                  (item) => InputChip(
                    label: Text(item),
                    onDeleted: () => setState(() => _avoid.remove(item)),
                  ),
                )
                .toList(),
          ),
          TextField(
            controller: _avoidCtrl,
            decoration: const InputDecoration(hintText: 'Add a dislike'),
            onSubmitted: (v) {
              if (v.trim().isEmpty) return;
              setState(() {
                _avoid.add(v.trim());
                _avoidCtrl.clear();
              });
            },
          ),
          _label('Max cooking time'),
          _chips(
            ['15 min', '30 min', '45 min', '60 min'],
            ['$_maxMinutes min'],
            (v) => setState(() => _maxMinutes = int.parse(v.split(' ').first)),
            single: true,
          ),
          _label('Weekly shopping budget (optional)'),
          TextField(
            controller: _budgetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixText: '£ ',
              hintText: 'e.g. 60',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _meals.isEmpty
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlannerPantrySelectScreen(
                          days: _days,
                          meals: _meals.toList(),
                          people: _people,
                          goals: _goals.toList(),
                          spice: _spice,
                          cuisines: _cuisines.toList(),
                          avoid: _avoid,
                          maxMinutes: _maxMinutes,
                          budget: double.tryParse(_budgetCtrl.text.trim()),
                          returnToPlannerTab: true,
                          closeSetupRoute: true,
                        ),
                      ),
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
            ),
            child: Text('Choose pantry ingredients', style: AppText.button()),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
        child: Text(text, style: AppText.label()),
      );

  Widget _chips(
    List<String> options,
    List<String> selected,
    ValueChanged<String> onTap, {
    bool single = false,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final on = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: on,
          onSelected: (_) => onTap(option),
          selectedColor: AppColors.sageMuted,
          checkmarkColor: AppColors.green,
          showCheckmark: false,
          shape: const StadiumBorder(),
          side: BorderSide(
            color: on ? AppColors.green.withValues(alpha: 0.35) : AppColors.border,
          ),
        );
      }).toList(),
    );
  }
}
