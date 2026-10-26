import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import 'floating_nav_bar.dart';

/// Eating story: macros only. Kept separate from Impact (rescued kg).
class EatingDashboard extends StatelessWidget {
  const EatingDashboard({
    super.key,
    required this.stats,
    required this.preferences,
  });

  final ImpactStats stats;
  final UserPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final letters = _letters();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, kFloatingNavClearance),
      children: [
        Text('Nutrients this week', style: AppText.section()),
        const SizedBox(height: 6),
        Text(
          'From meals you marked eaten. Tap a nutrient, then a day. Energy split uses 4 kcal per gram of protein or carbs and 9 kcal per gram of fat.',
          style: AppText.caption(fontWeight: FontWeight.w500),
        ),
        if (preferences.tracksIntake) ...[
          const SizedBox(height: 6),
          Text(
            'On your ${preferences.mealGoal.toLowerCase()} plan.',
            style: AppText.caption(fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 14),
        _NutrientExplorer(
          letters: letters,
          calories: stats.caloriesLast7Days.length == 7
              ? stats.caloriesLast7Days
              : List<int>.filled(7, 0),
          protein: _seven(stats.proteinLast7Days),
          carbs: _seven(stats.carbsLast7Days),
          fat: _seven(stats.fatLast7Days),
          fibre: _seven(stats.fibreLast7Days),
        ),
        const SizedBox(height: 28),
        Text('Lifetime totals', style: AppText.section()),
        const SizedBox(height: 8),
        _QuietRow(
          label: 'Calories',
          value: '${stats.caloriesEaten} kcal',
          accent: AppColors.forest,
        ),
        _QuietRow(
          label: 'Protein',
          value: '${stats.proteinEaten.toStringAsFixed(0)} g',
          accent: AppColors.proteinText,
        ),
        _QuietRow(
          label: 'Carbohydrates',
          value: '${stats.carbohydratesEaten.toStringAsFixed(0)} g',
          accent: AppColors.carbsText,
        ),
        _QuietRow(
          label: 'Fat',
          value: '${stats.fatEaten.toStringAsFixed(0)} g',
          accent: AppColors.fatText,
        ),
        _QuietRow(
          label: 'Fibre',
          value: '${stats.fibreEaten.toStringAsFixed(0)} g',
          accent: AppColors.fibreText,
        ),
        _QuietRow(
          label: 'Meals eaten',
          value: '${stats.mealsCooked}',
          accent: AppColors.skyText,
        ),
        const SizedBox(height: 14),
        Text(
          'Macros are from cooking events. Food rescued kilograms live on My Impact.',
          style: AppText.caption(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  List<double> _seven(List<double> values) {
    return values.length == 7 ? values : List<double>.filled(7, 0);
  }

  List<String> _letters() {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();
    return [
      for (var i = 0; i < 7; i++)
        names[today.subtract(Duration(days: 6 - i)).weekday - 1],
    ];
  }
}

class _NutrientExplorer extends StatefulWidget {
  const _NutrientExplorer({
    required this.letters,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fibre,
  });

  final List<String> letters;
  final List<int> calories;
  final List<double> protein;
  final List<double> carbs;
  final List<double> fat;
  final List<double> fibre;

  @override
  State<_NutrientExplorer> createState() => _NutrientExplorerState();
}

class _NutrientExplorerState extends State<_NutrientExplorer> {
  int _nutrient = 0;
  int? _day;

  static const _names = ['Calories', 'Protein', 'Carbs', 'Fat', 'Fibre'];
  static const _colors = [
    AppColors.forest,
    AppColors.proteinText,
    AppColors.carbsText,
    AppColors.fatText,
    AppColors.fibreText,
  ];

  List<double> get _values {
    switch (_nutrient) {
      case 1:
        return widget.protein;
      case 2:
        return widget.carbs;
      case 3:
        return widget.fat;
      case 4:
        return widget.fibre;
      default:
        return [for (final value in widget.calories) value.toDouble()];
    }
  }

  String _amount(double value) {
    if (_nutrient == 0) return '${value.round()} kcal';
    return '${value.toStringAsFixed(0)} g';
  }

  @override
  Widget build(BuildContext context) {
    final values = _values;
    final color = _colors[_nutrient];
    var maxValue = 1.0;
    for (final value in values) {
      if (value > maxValue) maxValue = value;
    }
    final day = _day;
    final proteinK = _sum(widget.protein, day) * 4;
    final carbsK = _sum(widget.carbs, day) * 4;
    final fatK = _sum(widget.fat, day) * 9;
    final energy = proteinK + carbsK + fatK;
    final fibre = _sum(widget.fibre, day);
    final scope = day == null ? 'This week' : widget.letters[day];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _names.length; i++)
              GestureDetector(
                onTap: () => setState(() => _nutrient = i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _nutrient == i ? _colors[i] : AppColors.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: _nutrient == i ? _colors[i] : AppColors.line,
                    ),
                  ),
                  child: Text(
                    _names[i],
                    style: AppText.caption(
                      color: _nutrient == i ? AppColors.surface : _colors[i],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 108,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _day = _day == i ? null : i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            values[i] <= 0 ? '0' : _amount(values[i]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption(
                              color: _day == i ? AppColors.ink : color,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: _day == i ? 16 : 12,
                              height:
                                  (8 + 54 * (values[i] / maxValue)).clamp(8, 62),
                              decoration: BoxDecoration(
                                color: _day == i ? AppColors.ink : color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.letters[i],
                            style: AppText.caption(
                              fontSize: 11,
                              color:
                                  _day == i ? AppColors.ink : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (day != null) ...[
          const SizedBox(height: 8),
          Text(
            '${widget.letters[day]} · ${_amount(values[day])}',
            style: AppText.caption(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text('$scope’s energy', style: AppText.label()),
        const SizedBox(height: 6),
        Text(
          'Protein and carbs are 4 kcal per gram. Fat is 9. Fibre stays in grams.',
          style: AppText.caption(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        if (energy <= 0)
          Text(
            'No energy logged ${day == null ? 'this week' : 'on this day'}.',
            style: AppText.caption(fontWeight: FontWeight.w500),
          )
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  if (proteinK > 0)
                    Expanded(
                      flex: _flex(proteinK),
                      child: const ColoredBox(color: AppColors.proteinText),
                    ),
                  if (carbsK > 0)
                    Expanded(
                      flex: _flex(carbsK),
                      child: const ColoredBox(color: AppColors.carbsText),
                    ),
                  if (fatK > 0)
                    Expanded(
                      flex: _flex(fatK),
                      child: const ColoredBox(color: AppColors.fatText),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EnergyChip(
                label: 'Protein ${_pct(proteinK, energy)}%',
                color: AppColors.proteinText,
                selected: _nutrient == 1,
                onTap: () => setState(() => _nutrient = 1),
              ),
              _EnergyChip(
                label: 'Carbs ${_pct(carbsK, energy)}%',
                color: AppColors.carbsText,
                selected: _nutrient == 2,
                onTap: () => setState(() => _nutrient = 2),
              ),
              _EnergyChip(
                label: 'Fat ${_pct(fatK, energy)}%',
                color: AppColors.fatText,
                selected: _nutrient == 3,
                onTap: () => setState(() => _nutrient = 3),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Fibre ${fibre.toStringAsFixed(0)} g. It is not part of the energy split.',
          style: AppText.caption(
            color: AppColors.fibreText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  double _sum(List<double> values, int? day) {
    if (day != null) return day < values.length ? values[day] : 0;
    return values.fold<double>(0, (sum, value) => sum + value);
  }

  int _pct(double part, double total) {
    if (total <= 0) return 0;
    return ((part / total) * 100).round();
  }

  int _flex(double kcal) {
    final n = kcal.round();
    if (n < 1) return 1;
    return n > 100000 ? 100000 : n;
  }
}

class _EnergyChip extends StatelessWidget {
  const _EnergyChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: AppText.caption(
            color: selected ? AppColors.surface : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _QuietRow extends StatelessWidget {
  const _QuietRow({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppText.body())),
          const SizedBox(width: 10),
          Text(value, style: AppText.label(color: accent)),
        ],
      ),
    );
  }
}
