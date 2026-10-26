import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import 'floating_nav_bar.dart';
import 'recipe_photo.dart';

/// Implied kg CO₂e per kg of household food waste from WRAP national totals.
/// WRAP Household Food and Drink Waste in the UK 2022: ~16 Mt CO₂e / ~6.0 Mt ≈ 2.7.
/// WRAP Household Food and Drink Waste in the UK 2021/22: ~18 Mt CO₂e / ~6.4 Mt ≈ 2.8.
/// Shown as a range because WRAP does not publish a single per-kg product factor.
const wrapWasteCo2ePerKgLow = 2.5;
const wrapWasteCo2ePerKgHigh = 2.9;

class ImpactSnapshot extends StatelessWidget {
  const ImpactSnapshot({
    super.key,
    required this.stats,
    required this.preferences,
    this.onOpen,
  });

  final ImpactStats stats;
  final UserPreferences preferences;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final saved = stats.estimatedWasteAvoidedKg ?? 0;
    final window = preferences.expiryReminderDays;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Food rescued', style: AppText.label(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Rescued = used while inside your $window-day window.',
              style: AppText.caption(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    value: '${saved.toStringAsFixed(2)} kg',
                    label: 'Rescued',
                    color: AppColors.forest,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    value: '${stats.mealsCooked}',
                    label: 'Meals eaten',
                    color: AppColors.skyText,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    value: '${stats.ingredientsUsedBeforeExpiry}',
                    label: 'Items caught',
                    color: AppColors.peachText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppText.title(fontSize: 18, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.body(fontSize: 11),
        ),
      ],
    );
  }
}

class ImpactDashboard extends StatefulWidget {
  const ImpactDashboard({
    super.key,
    required this.stats,
    required this.preferences,
    this.rescueFlash,
    this.onFlashConsumed,
  });

  final ImpactStats stats;
  final UserPreferences preferences;
  final ImpactRescueFlash? rescueFlash;
  final VoidCallback? onFlashConsumed;

  @override
  State<ImpactDashboard> createState() => _ImpactDashboardState();
}

class _ImpactDashboardState extends State<ImpactDashboard>
    with SingleTickerProviderStateMixin {
  final _shareKey = GlobalKey();
  bool _sharing = false;
  int? _selectedDay;
  String? _selectedFood;
  bool _showHistory = false;
  late final AnimationController _countCtrl;
  late Animation<double> _countAnim;
  String? _flashLine;

  @override
  void initState() {
    super.initState();
    final saved = widget.stats.estimatedWasteAvoidedKg ?? 0;
    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _countAnim = AlwaysStoppedAnimation(saved);
    _maybePlayFlash(widget.rescueFlash);
  }

  @override
  void didUpdateWidget(covariant ImpactDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rescueFlash != null &&
        widget.rescueFlash != oldWidget.rescueFlash) {
      _maybePlayFlash(widget.rescueFlash);
    } else if (widget.rescueFlash == null &&
        (widget.stats.estimatedWasteAvoidedKg ?? 0) !=
            (oldWidget.stats.estimatedWasteAvoidedKg ?? 0)) {
      final next = widget.stats.estimatedWasteAvoidedKg ?? 0;
      _countAnim = AlwaysStoppedAnimation(next);
    }
  }

  void _maybePlayFlash(ImpactRescueFlash? flash) {
    if (flash == null) return;
    final end = flash.previousKg + flash.rescuedKg;
    _flashLine =
        'You just kept ${flash.rescuedKg.toStringAsFixed(2)} kg of ${flash.highlightFood.toLowerCase()} out of the bin.';
    _countAnim = Tween<double>(begin: flash.previousKg, end: end).animate(
      CurvedAnimation(parent: _countCtrl, curve: Curves.easeOutCubic),
    );
    _countCtrl
      ..reset()
      ..forward().whenComplete(() {
        widget.onFlashConsumed?.call();
      });
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final boundary =
          _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/plateful-impact.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Food I kept out of the bin with Plateful.',
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final saved = stats.estimatedWasteAvoidedKg ?? 0;
    final days = _seven(stats.savedKgLast7Days);
    final previous = _seven(stats.savedKgPrevious7Days);
    final thisWeek = days.fold<double>(0, (sum, value) => sum + value);
    final lastWeek = previous.fold<double>(0, (sum, value) => sum + value);
    final window = widget.preferences.expiryReminderDays;
    final aimKg = widget.preferences.weeklyRescueAimKg;
    final linkedMeals = _selectedFood == null
        ? stats.recentMeals
        : [
            for (final meal in stats.recentMeals)
              if (meal.rescuedFoods.any(
                (food) => food.toLowerCase() == _selectedFood!.toLowerCase(),
              ))
                meal,
          ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, kFloatingNavClearance),
      children: [
        Text(
          'Rescued = used while inside your $window-day window.',
          style: AppText.caption(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        RepaintBoundary(
          key: _shareKey,
          child: _HeroCard(
            countAnim: _countAnim,
            saved: saved,
            days: days,
            previous: previous,
            thisWeek: thisWeek,
            lastWeek: lastWeek,
            windowDays: window,
            aimKg: aimKg,
            selectedDay: _selectedDay,
            onSelectDay: (i) => setState(() => _selectedDay = i),
            letters: _letters(),
            weekLine: _weekLine(thisWeek, lastWeek),
            bestMilestone: _bestMilestone(stats, saved),
            flashLine: _flashLine,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _sharing ? null : _share,
          icon: const Icon(PhosphorIconsRegular.shareNetwork, size: 18),
          label: Text(_sharing ? 'Preparing…' : 'Share impact card'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => _explain(window),
            child: Text(
              'How we calculate',
              style: AppText.caption(
                color: AppColors.forest,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (!stats.hasData)
          Text(
            'Cook something from your pantry to start. Empty days stay at 0.',
            style: AppText.body(),
          ),
        if (stats.mealsMissingExpiry > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${stats.mealsMissingExpiry} ${stats.mealsMissingExpiry == 1 ? 'meal' : 'meals'} used only food with no expiry date, so ${stats.mealsMissingExpiry == 1 ? 'it is' : 'they are'} not counted in rescued kg.',
            style: AppText.caption(fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Text('Caught in time', style: AppText.section())),
            TextButton(
              onPressed: () => _explain(window),
              child: Text(
                'How we calculate',
                style: AppText.caption(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Inside your $window-day reminder versus food that still had longer. Counts of pantry uses.',
          style: AppText.caption(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        _CaughtBar(
          rescued: stats.ingredientsUsedBeforeExpiry,
          total: stats.usageEvents,
          windowDays: window,
        ),
        if (stats.topRescuedFoods.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('Top rescued foods', style: AppText.section()),
              ),
              TextButton(
                onPressed: () => _explain(window),
                child: Text(
                  'How we calculate',
                  style: AppText.caption(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Kilograms rescued inside your $window-day window. Tap a food to see meals.',
            style: AppText.caption(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _FoodBars(
            foods: stats.topRescuedFoods,
            selected: _selectedFood,
            onTap: (name) => setState(() {
              _selectedFood = _selectedFood == name ? null : name;
            }),
          ),
        ],
        if (_selectedFood != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text(_selectedFood!),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _selectedFood = null),
              onPressed: () => setState(() => _selectedFood = null),
              backgroundColor: AppColors.sageSoft,
              side: const BorderSide(color: AppColors.sageBorder),
              labelStyle: AppText.caption(
                color: AppColors.forest,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (linkedMeals.isNotEmpty &&
            (_selectedFood != null || stats.topRescuedFoods.isNotEmpty)) ...[
          const SizedBox(height: 16),
          Text(
            _selectedFood == null ? 'Recent rescues' : 'Meals with $_selectedFood',
            style: AppText.section(),
          ),
          const SizedBox(height: 12),
          _RecentMeals(meals: linkedMeals.take(5).toList()),
        ],
        const SizedBox(height: 24),
        Text('Milestones', style: AppText.section()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Badge(
              label: 'First rescue',
              earned: stats.ingredientsUsedBeforeExpiry > 0,
            ),
            _Badge(
              label: '1 kg saved',
              earned: saved >= 1,
            ),
            _Badge(
              label: '7-day streak',
              earned: stats.cookStreakDays >= 7,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _showHistory = !_showHistory),
          child: Text(
            _showHistory ? 'Hide history' : 'See history',
            style: AppText.caption(
              color: AppColors.forest,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (_showHistory) ...[
          _MonthGrid(
            cookedDays: stats.monthCookedDays,
            rescuedDays: stats.monthRescuedDays,
          ),
          const SizedBox(height: 8),
          Text(
            'Forest = rescued day. Mid grey = cooked. Light grey = empty.',
            style: AppText.caption(fontWeight: FontWeight.w500),
          ),
          if (stats.cumulativeSavedKg.length >= 2) ...[
            const SizedBox(height: 20),
            Text('Saved over time', style: AppText.section()),
            const SizedBox(height: 10),
            _CumulativeLine(
              values: stats.cumulativeSavedKg,
              fromFirst: stats.cumulativeIsComplete,
            ),
          ],
        ],
        const SizedBox(height: 20),
        Text(
          'Eating macros live on the Eating tab. Impact stays on rescued kilograms.',
          style: AppText.caption(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String? _bestMilestone(ImpactStats stats, double saved) {
    if (stats.cookStreakDays >= 7) return '7-day streak';
    if (saved >= 1) return '1 kg saved';
    if (stats.ingredientsUsedBeforeExpiry > 0) return 'First rescue';
    return null;
  }

  List<double> _seven(List<double> values) {
    return values.length == 7 ? values : List<double>.filled(7, 0);
  }

  String _weekLine(double thisWeek, double lastWeek) {
    final delta = thisWeek - lastWeek;
    final mark = delta > 0.005 ? '↑' : delta < -0.005 ? '↓' : '→';
    return '$mark ${thisWeek.toStringAsFixed(2)} kg this week · ${lastWeek.toStringAsFixed(2)} kg last week';
  }

  List<String> _letters() {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();
    return [
      for (var i = 0; i < 7; i++)
        names[today.subtract(Duration(days: 6 - i)).weekday - 1],
    ];
  }

  void _explain(int windowDays) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How we calculate', style: AppText.section()),
                const SizedBox(height: 12),
                Text(
                  'Rescued = pantry food used while inside your $windowDays-day expiry reminder. Piece, slice, and clove amounts use typical weights. Grams and millilitres convert directly. Meals with no expiry dates are not counted.',
                  style: AppText.body(height: 1.4),
                ),
                const SizedBox(height: 10),
                Text(
                  'CO₂e is shown as a range using ${wrapWasteCo2ePerKgLow.toStringAsFixed(1)}–${wrapWasteCo2ePerKgHigh.toStringAsFixed(1)} kg CO₂e per kg. That range is derived from WRAP’s national household food-waste totals: Household Food and Drink Waste in the UK 2022 (~16 Mt CO₂e / ~6.0 Mt ≈ 2.7) and 2021/22 (~18 Mt CO₂e / ~6.4 Mt ≈ 2.8). WRAP does not publish a single per-kg product factor for waste avoided.',
                  style: AppText.body(height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.countAnim,
    required this.saved,
    required this.days,
    required this.previous,
    required this.thisWeek,
    required this.lastWeek,
    required this.windowDays,
    required this.aimKg,
    required this.selectedDay,
    required this.onSelectDay,
    required this.letters,
    required this.weekLine,
    required this.bestMilestone,
    required this.flashLine,
  });

  final Animation<double> countAnim;
  final double saved;
  final List<double> days;
  final List<double> previous;
  final double thisWeek;
  final double lastWeek;
  final int windowDays;
  final double aimKg;
  final int? selectedDay;
  final ValueChanged<int> onSelectDay;
  final List<String> letters;
  final String weekLine;
  final String? bestMilestone;
  final String? flashLine;

  @override
  Widget build(BuildContext context) {
    final co2Low = saved * wrapWasteCo2ePerKgLow;
    final co2High = saved * wrapWasteCo2ePerKgHigh;
    final aim = aimKg <= 0 ? 0.5 : aimKg;
    final aimFill = (thisWeek / aim).clamp(0.0, 1.0);
    var maxDay = 0.01;
    for (final value in [...days, ...previous]) {
      if (value > maxDay) maxDay = value;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.sageSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Food rescued', style: AppText.caption(color: AppColors.forest)),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: countAnim,
            builder: (context, _) {
              return Text(
                '${countAnim.value.toStringAsFixed(1)} kg',
                style: AppText.stat(color: AppColors.forest),
              );
            },
          ),
          if (flashLine != null) ...[
            const SizedBox(height: 6),
            Text(
              flashLine!,
              style: AppText.body(fontSize: 13, color: AppColors.ink),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'About ${co2Low.toStringAsFixed(1)}–${co2High.toStringAsFixed(1)} kg CO₂e · WRAP household waste estimate',
            style: AppText.body(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Rescued = used while inside your $windowDays-day window.',
            style: AppText.caption(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: aimFill <= 0 ? 0.02 : aimFill,
              minHeight: 6,
              backgroundColor: AppColors.surface,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${thisWeek.toStringAsFixed(2)} / ${aim.toStringAsFixed(aim == aim.roundToDouble() ? 0 : 1)} kg this week’s aim',
            style: AppText.caption(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _LegendDot(color: AppColors.forest, label: 'This week'),
              const SizedBox(width: 14),
              _LegendDot(color: AppColors.sageBorder, label: 'Last week'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onSelectDay(i),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 68,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  _DayBar(
                                    height: 8 + 56 * (previous[i] / maxDay),
                                    width: 14,
                                    color: AppColors.sageBorder,
                                  ),
                                  _DayBar(
                                    height: 8 + 56 * (days[i] / maxDay),
                                    width: 8,
                                    color: selectedDay == i
                                        ? AppColors.ink
                                        : AppColors.forest,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              days[i] <= 0 ? '0' : '',
                              style: AppText.caption(
                                fontSize: 10,
                                color: AppColors.forest,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              letters[i],
                              style: AppText.caption(
                                color: selectedDay == i
                                    ? AppColors.ink
                                    : AppColors.forest,
                                fontSize: 11,
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
          if (selectedDay != null) ...[
            const SizedBox(height: 8),
            Text(
              '${letters[selectedDay!]} · ${days[selectedDay!].toStringAsFixed(2)} kg',
              style: AppText.caption(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(weekLine, style: AppText.caption(fontWeight: FontWeight.w700)),
          if (bestMilestone != null) ...[
            const SizedBox(height: 6),
            Text(
              'Milestone: $bestMilestone',
              style: AppText.caption(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.caption(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.height,
    required this.width,
    required this.color,
  });

  final double height;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: width,
        height: height.clamp(8, 68),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _CaughtBar extends StatelessWidget {
  const _CaughtBar({
    required this.rescued,
    required this.total,
    required this.windowDays,
  });

  final int rescued;
  final int total;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) {
      return Text(
        'Caught in time appears once a meal uses pantry items.',
        style: AppText.caption(fontWeight: FontWeight.w500),
      );
    }
    final longer = (total - rescued).clamp(0, total);
    final caught = rescued.clamp(0, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                if (caught > 0)
                  Expanded(
                    flex: caught,
                    child: const ColoredBox(color: AppColors.sageBorder),
                  ),
                if (longer > 0)
                  Expanded(
                    flex: longer,
                    child: const ColoredBox(color: AppColors.skyText),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$caught caught in time · $longer still had longer',
          style: AppText.caption(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Sage is food inside your $windowDays-day reminder at cook time. Sky is food that still had longer.',
          style: AppText.caption(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _FoodBars extends StatelessWidget {
  const _FoodBars({
    required this.foods,
    required this.selected,
    required this.onTap,
  });

  final List<RescuedFood> foods;
  final String? selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final maxKg = foods.fold<double>(0.01, (max, food) {
      return food.kilograms > max ? food.kilograms : max;
    });
    return Column(
      children: [
        for (final food in foods)
          GestureDetector(
            onTap: () => onTap(food.name),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.itemTitle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${food.kilograms.toStringAsFixed(2)} kg',
                        style: AppText.caption(color: AppColors.forest),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: food.kilograms / maxKg,
                      minHeight: 6,
                      backgroundColor: AppColors.surface,
                      color: selected == food.name
                          ? AppColors.ink
                          : AppColors.forest,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentMeals extends StatelessWidget {
  const _RecentMeals({required this.meals});

  final List<ImpactMeal> meals;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final meal in meals)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: RecipePhoto(url: meal.imageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.title, style: AppText.itemTitle()),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEE · d MMM').format(meal.timestamp),
                        style: AppText.caption(fontWeight: FontWeight.w500),
                      ),
                      if (meal.rescuedKg > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${meal.rescuedKg.toStringAsFixed(2)} kg rescued'
                          '${meal.rescuedFoods.isEmpty ? '' : ' · ${meal.rescuedFoods.take(2).join(', ')}'}',
                          style: AppText.caption(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CumulativeLine extends StatelessWidget {
  const _CumulativeLine({required this.values, required this.fromFirst});

  final List<double> values;
  final bool fromFirst;

  @override
  Widget build(BuildContext context) {
    final last = values.isEmpty ? 0.0 : values.last;
    final dots = <int>[];
    if (values.isNotEmpty) dots.add(0);
    for (var i = 0; i < values.length; i++) {
      if (values[i] >= 1) {
        dots.add(i);
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${last.toStringAsFixed(2)} kg rescued on this line',
          style: AppText.caption(
            color: AppColors.forest,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(values: values, dots: dots),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              fromFirst ? 'First rescue' : '12 weeks ago',
              style: AppText.caption(fontSize: 11),
            ),
            const Spacer(),
            Text('Today', style: AppText.caption(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.values, required this.dots});

  final List<double> values;
  final List<int> dots;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    var maxV = 0.01;
    for (final value in values) {
      if (value > maxV) maxV = value;
    }
    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? 0.0
          : size.width * (i / (values.length - 1));
      final y = size.height - (values[i] / maxV) * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()
        ..color = AppColors.sageSoft
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = AppColors.ink;
    for (final index in dots) {
      if (index < 0 || index >= values.length) continue;
      final x = values.length == 1
          ? 0.0
          : size.width * (index / (values.length - 1));
      final y = size.height - (values[index] / maxV) * (size.height - 8) - 4;
      canvas.drawCircle(Offset(x, y), 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.dots != dots;
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.cookedDays, required this.rescuedDays});

  final List<int> cookedDays;
  final List<int> rescuedDays;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final count = DateTime(now.year, now.month + 1, 0).day;
    final lead = first.weekday - 1;
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final cooked = cookedDays.toSet();
    final rescued = rescuedDays.toSet();
    final month = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][now.month - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(month, style: AppText.caption(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final letter in letters)
              Expanded(
                child: Text(
                  letter,
                  textAlign: TextAlign.center,
                  style: AppText.caption(fontSize: 11),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var day = 1; day <= count; day++)
              _MonthCell(
                rescued: rescued.contains(day),
                cooked: cooked.contains(day),
              ),
          ],
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({required this.rescued, required this.cooked});

  final bool rescued;
  final bool cooked;

  @override
  Widget build(BuildContext context) {
    final color = rescued
        ? AppColors.forest
        : cooked
            ? const Color(0xFF9AA39C)
            : const Color(0xFFD8DCD6);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.earned});

  final String label;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: earned ? AppColors.sageSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: earned ? AppColors.sageBorder : AppColors.line,
        ),
      ),
      child: Text(
        label,
        style: AppText.caption(
          color: earned ? AppColors.forest : AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
