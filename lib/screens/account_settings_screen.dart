import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../models/user_preferences.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/pressable.dart';
import '../widgets/rule_pill.dart';
import '../widgets/section_card.dart';
import '../widgets/toggle_chip.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _avoidCtrl = TextEditingController();
  Timer? _savedTimer;
  Timer? _hideTimer;
  var _showSaved = false;

  @override
  void dispose() {
    _savedTimer?.cancel();
    _hideTimer?.cancel();
    _avoidCtrl.dispose();
    super.dispose();
  }

  Future<void> _update(
    AppState state,
    UserPreferences Function(UserPreferences) change,
  ) async {
    await state.updatePreferences(change(state.preferences));
    _scheduleSaved();
  }

  void _scheduleSaved() {
    _savedTimer?.cancel();
    _savedTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _showSaved = true);
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _showSaved = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final prefs = state.preferences;

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Row(
                  children: [
                    CircleIconButton(
                      icon: PhosphorIconsRegular.arrowLeft,
                      semanticLabel: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Food preferences',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.h1Small(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  prefs.recipePreview,
                  style: AppText.label(fontSize: 14, color: AppColors.forest),
                ),
                const SizedBox(height: 6),
                Text(
                  'Allergies and diet are hard rules. Halal and Kosher can sit with one way of eating.',
                  style: AppText.body(fontSize: 14),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  header: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Allergies',
                          style: AppText.label(fontSize: 15).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      RulePill.never('Never included'),
                    ],
                  ),
                  child: _wrap(
                    UserPreferences.allergyOptions,
                    prefs.allergies,
                    ToggleChipVariant.danger,
                    (value) => _update(
                      state,
                      (p) => p.copyWith(allergies: _toggle(p.allergies, value)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  header: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Diet',
                          style: AppText.label(fontSize: 15).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      RulePill.always('Always followed'),
                    ],
                  ),
                  child:                     _wrap(
                    UserPreferences.dietOptions,
                    prefs.diets,
                    ToggleChipVariant.solid,
                    (value) => _update(
                      state,
                      (p) => p.copyWith(
                        diets: UserPreferences.toggleDiet(p.diets, value),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  header: Text(
                    'Ingredients to avoid',
                    style: AppText.label(fontSize: 15).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _avoidField(state)),
                          const SizedBox(width: 8),
                          Pressable(
                            semanticLabel: 'Add ingredient to avoid',
                            onTap: () => _addAvoid(state),
                            child: Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.forest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                PhosphorIconsRegular.plus,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (prefs.avoidIngredients.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final item in prefs.avoidIngredients)
                              ToggleChip(
                                label: item,
                                selected: true,
                                variant: ToggleChipVariant.danger,
                                onTap: () {},
                                onRemove: () => _update(
                                  state,
                                  (p) => p.copyWith(
                                    avoidIngredients: p.avoidIngredients
                                        .where((e) => e != item)
                                        .toList(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  header: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Favourite cuisines',
                          style: AppText.label(fontSize: 15).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Nudges, not rules',
                        style: AppText.caption(),
                      ),
                    ],
                  ),
                  child: _wrap(
                    UserPreferences.cuisineOptions,
                    prefs.favouriteCuisines,
                    ToggleChipVariant.soft,
                    (value) => _update(
                      state,
                      (p) => p.copyWith(
                        favouriteCuisines: _toggle(p.favouriteCuisines, value),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  collapsed: true,
                  header: Text('Cooking', style: AppText.section()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spice tolerance', style: AppText.label()),
                      const SizedBox(height: 8),
                      _wrap(
                        UserPreferences.spiceOptions,
                        [prefs.spiceTolerance],
                        ToggleChipVariant.solid,
                        (value) => _update(
                          state,
                          (p) => p.copyWith(spiceTolerance: value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _stepperRow(
                        'People in household',
                        prefs.householdSize,
                        1,
                        8,
                        (v) => _update(state, (p) => p.copyWith(householdSize: v)),
                      ),
                      _stepperRow(
                        'Default servings',
                        prefs.defaultServings,
                        1,
                        8,
                        (v) =>
                            _update(state, (p) => p.copyWith(defaultServings: v)),
                      ),
                      const SizedBox(height: 8),
                      Text('Max cooking time', style: AppText.label()),
                      const SizedBox(height: 8),
                      _wrap(
                        UserPreferences.cookMinuteOptions
                            .map((m) => '$m min')
                            .toList(),
                        ['${prefs.maxCookMinutes} min'],
                        ToggleChipVariant.solid,
                        (value) {
                          final minutes =
                              int.tryParse(value.split(' ').first) ?? 30;
                          _update(
                            state,
                            (p) => p.copyWith(maxCookMinutes: minutes),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Cooking skill', style: AppText.label()),
                      const SizedBox(height: 8),
                      _wrap(
                        UserPreferences.skillOptions,
                        [prefs.cookingSkill],
                        ToggleChipVariant.solid,
                        (value) => _update(
                          state,
                          (p) => p.copyWith(cookingSkill: value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Meal goal', style: AppText.label()),
                      const SizedBox(height: 8),
                      _wrap(
                        UserPreferences.goalOptions,
                        [prefs.mealGoal],
                        ToggleChipVariant.solid,
                        (value) =>
                            _update(state, (p) => p.copyWith(mealGoal: value)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  collapsed: true,
                  header: Text('Kitchen', style: AppText.section()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Equipment you have', style: AppText.label()),
                      const SizedBox(height: 8),
                      _wrap(
                        UserPreferences.equipmentOptions,
                        prefs.equipment,
                        ToggleChipVariant.soft,
                        (value) => _update(
                          state,
                          (p) => p.copyWith(equipment: _toggle(p.equipment, value)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Units', style: AppText.label()),
                      const SizedBox(height: 8),
                      _wrap(
                        const ['metric', 'imperial'],
                        [prefs.units],
                        ToggleChipVariant.solid,
                        (value) =>
                            _update(state, (p) => p.copyWith(units: value)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Flag ingredients this many days before expiry',
                        style: AppText.label(),
                      ),
                      const SizedBox(height: 8),
                      _wrap(
                        const ['3 days', '5 days', '7 days', '14 days'],
                        ['${prefs.expiryReminderDays} days'],
                        ToggleChipVariant.solid,
                        (value) {
                          final days = int.tryParse(value.split(' ').first) ?? 7;
                          _update(
                            state,
                            (p) => p.copyWith(expiryReminderDays: days),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Weekly rescue aim', style: AppText.label()),
                      const SizedBox(height: 4),
                      Text(
                        'The only target on Impact. Food saved counts items inside the expiry window above.',
                        style: AppText.caption(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      _wrap(
                        const ['0.25 kg', '0.5 kg', '1 kg'],
                        [_aimChip(prefs.weeklyRescueAimKg)],
                        ToggleChipVariant.solid,
                        (value) {
                          final kg = double.tryParse(value.split(' ').first) ?? 0.5;
                          _update(
                            state,
                            (p) => p.copyWith(weeklyRescueAimKg: kg),
                          );
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Ask before deducting pantry after cooking',
                          style: AppText.label(),
                        ),
                        value: prefs.askBeforeDeducting,
                        activeThumbColor: AppColors.forest,
                        onChanged: (v) => _update(
                          state,
                          (p) => p.copyWith(askBeforeDeducting: v),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Demo', style: AppText.label()),
                      const SizedBox(height: 4),
                      Text(
                        'Fills about two weeks of cooking and rescues so Impact is not empty for judges.',
                        style: AppText.caption(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await state.loadDemoImpactWeek();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Demo week loaded. Open Impact to see the charts.',
                              ),
                            ),
                          );
                        },
                        child: const Text('Load demo week'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await state.resetNutrientGraphs();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Calories, nutrients, and carbon savings are back at zero. The meal that saved carbon is off your plan.',
                              ),
                            ),
                          );
                        },
                        child: const Text('Reset all graphs'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  collapsed: true,
                  header: Text('Reminders', style: AppText.section()),
                  child: Column(
                    children: [
                      _reminder(
                        'Ingredients approaching expiry',
                        prefs.notifyExpiry,
                        (v) => _update(state, (p) => p.copyWith(notifyExpiry: v)),
                      ),
                      _reminder(
                        'Weekly meal plan nudge',
                        prefs.notifyMealPlan,
                        (v) =>
                            _update(state, (p) => p.copyWith(notifyMealPlan: v)),
                      ),
                      _reminder(
                        'Shopping list reminder',
                        prefs.notifyShopping,
                        (v) =>
                            _update(state, (p) => p.copyWith(notifyShopping: v)),
                      ),
                      _reminder(
                        'Meal prep reminder',
                        prefs.notifyPrep,
                        (v) => _update(state, (p) => p.copyWith(notifyPrep: v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedSlide(
                offset: _showSaved ? Offset.zero : const Offset(0, -0.4),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _showSaved ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text('Saved', style: AppText.label(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avoidField(AppState state) {
    return Container(
      height: 46,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.ground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _avoidCtrl,
        style: AppText.body(color: AppColors.ink, fontSize: 15),
        decoration: InputDecoration(
          isCollapsed: true,
          hintText: 'e.g. mushrooms, coriander',
          hintStyle: AppText.body(fontSize: 15),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
        onSubmitted: (_) => _addAvoid(state),
      ),
    );
  }

  String _aimChip(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toStringAsFixed(0)} kg';
    final trimmed = kg.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    return '$trimmed kg';
  }

  Widget _wrap(
    List<String> options,
    List<String> selected,
    ToggleChipVariant variant,
    ValueChanged<String> onTap,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final option in options)
          ToggleChip(
            label: option,
            selected: selected.contains(option),
            variant: variant,
            onTap: () => onTap(option),
          ),
      ],
    );
  }

  Widget _reminder(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppText.label()),
      value: value,
      activeThumbColor: AppColors.forest,
      onChanged: onChanged,
    );
  }

  void _addAvoid(AppState state) {
    final text = _avoidCtrl.text.trim();
    if (text.isEmpty) return;
    if (state.preferences.avoidIngredients
        .any((e) => e.toLowerCase() == text.toLowerCase())) {
      _avoidCtrl.clear();
      return;
    }
    _update(
      state,
      (p) => p.copyWith(avoidIngredients: [...p.avoidIngredients, text]),
    );
    _avoidCtrl.clear();
  }

  List<String> _toggle(List<String> current, String value) {
    if (current.contains(value)) {
      return current.where((e) => e != value).toList();
    }
    return [...current, value];
  }

  Widget _stepperRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.label())),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(PhosphorIconsRegular.minus),
          ),
          Text('$value', style: AppText.title(fontSize: 18)),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(PhosphorIconsRegular.plus),
          ),
        ],
      ),
    );
  }
}
