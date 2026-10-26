import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../utils/expiry.dart';
import '../utils/food_facts.dart';
import '../theme/app_typography.dart';
import '../widgets/eating_dashboard.dart';
import '../widgets/impact_dashboard.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/ingredient_card.dart';
import '../widgets/profile_avatar_button.dart';
import '../widgets/recipe_card.dart';
import 'course_select_screen.dart';
import 'ingredient_detail_screen.dart';
import 'pantry_import_screen.dart';
import 'recipe_detail_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(state.preferences.displayName),
                        style: AppText.caption(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _segment == 0 ? 'Your Kitchen' : 'My Pantry',
                        style: AppText.display(fontSize: 28),
                      ),
                    ],
                  ),
                ),
                const ProfileAvatarButton(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.creamDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _Seg(
                    label: 'Food',
                    selected: _segment == 0,
                    onTap: () => setState(() => _segment = 0),
                  ),
                  _Seg(
                    label: 'Saved',
                    selected: _segment == 1,
                    onTap: () => setState(() => _segment = 1),
                  ),
                  _Seg(
                    label: 'Impact',
                    selected: _segment == 2,
                    onTap: () => setState(() => _segment = 2),
                  ),
                  _Seg(
                    label: 'Eating',
                    selected: _segment == 3,
                    onTap: () => setState(() => _segment = 3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (_segment) {
              0 => _IngredientsTab(state: state),
              1 => _SavedTab(state: state),
              2 => ImpactDashboard(
                  stats: state.impact,
                  preferences: state.preferences,
                  rescueFlash: state.lastRescueFlash,
                  onFlashConsumed: state.clearLastRescueFlash,
                ),
              _ => EatingDashboard(
                  stats: state.impact,
                  preferences: state.preferences,
                ),
            },
          ),
        ],
      ),
    );
  }
}

String _greeting(String displayName) {
  final hour = DateTime.now().hour;
  final hello = hour < 12
      ? 'Good morning'
      : hour < 17
          ? 'Good afternoon'
          : 'Good evening';
  final name = displayName.trim();
  if (name.isEmpty) return hello;
  return '$hello, $name';
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.label(
              fontSize: 12,
              color: selected ? AppColors.green : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientsTab extends StatefulWidget {
  const _IngredientsTab({required this.state});

  final AppState state;

  @override
  State<_IngredientsTab> createState() => _IngredientsTabState();
}

class _IngredientsTabState extends State<_IngredientsTab> {
  final Set<String> _selected = {};
  final Set<String> _binned = {};
  String _place = 'All items';

  AppState get state => widget.state;

  void _openCook({List<String>? focus}) {
    state.setShellTab(0);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseSelectScreen(
          fromPantry: true,
          focusIngredients: focus,
        ),
      ),
    );
  }

  void _toggle(PantryIngredient item) {
    if (!item.isAvailable) return;
    setState(() {
      if (_selected.contains(item.id)) {
        _selected.remove(item.id);
      } else {
        _selected.add(item.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final available = _inPlace(state.availableIngredients);
    final used = _inPlace(state.previouslyUsedIngredients);
    final expired = _inPlace(state.expiredIngredients);
    final urgent = _inPlace(state.urgentIngredients);
    final week = _inPlace(state.weekIngredients);
    final rest = _inPlace(state.stableIngredients);
    final expiring = [...urgent, ...week];
    final selectedItems =
        available.where((i) => _selected.contains(i.id)).toList();

    final soonCount = state.useSoonIngredients.length;
    final cookLabel = selectedItems.isEmpty
        ? (soonCount == 0
            ? 'Find recipes'
            : soonCount == 1
                ? 'Cook what’s due soon'
                : 'Cook $soonCount due soon')
        : 'Cook ${selectedItems.length} selected';
    final useSoonMode = selectedItems.isEmpty && soonCount > 0;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Swipe a row to cook or bin it',
                    style: AppText.caption(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Add item',
                    onPressed: () => _showAddSheet(context, state),
                    icon: const Icon(Icons.add, color: AppColors.green),
                  ),
                ],
              ),
            ),
            Expanded(
              child: available.isEmpty && used.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          'Your pantry is empty. Use the camera to add photos, or tap + to type one in.',
                          textAlign: TextAlign.center,
                          style: AppText.body(),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        kFloatingNavClearance + 64,
                      ),
                      children: [
                        _summaryCards(expiring),
                        const SizedBox(height: 14),
                        _placeChips(),
                        const SizedBox(height: 18),
                        _section(
                          context,
                          'Expiring soon',
                          expiring,
                        ),
                        _section(context, 'Expired', expired),
                        _section(
                          context,
                          expiring.isEmpty && expired.isEmpty
                              ? 'All items'
                              : 'Later',
                          rest,
                        ),
                        _section(
                          context,
                          'Previously used',
                          used,
                          selectable: false,
                        ),
                      ],
                    ),
            ),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: kFloatingNavClearance - 16,
          child: _CookPill(
            label: cookLabel,
            useSoon: useSoonMode,
            onPressed: available.isEmpty
                ? null
                : () {
                    final selectedCookable = selectedItems
                        .where(
                          (i) => ExpiryInfo.urgency(i) != ExpiryUrgency.expired,
                        )
                        .toList();
                    if (selectedItems.isNotEmpty && selectedCookable.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Expired food cannot be cooked. Pick items that are still in date.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (selectedCookable.isEmpty &&
                        state.cookableIngredients.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nothing in the pantry is still edible. Add fresh items first.',
                          ),
                        ),
                      );
                      return;
                    }
                    _openCook(
                      focus: selectedCookable.isEmpty
                          ? state.useSoonIngredients.map((i) => i.name).toList()
                          : selectedCookable.map((i) => i.name).toList(),
                    );
                  },
          ),
        ),
      ],
    );
  }

  List<PantryIngredient> _inPlace(List<PantryIngredient> items) {
    if (_place == 'All items') return items;
    return [
      for (final item in items)
        if (_bucket(item) == _place) item,
    ];
  }

  String _bucket(PantryIngredient item) {
    final raw = (item.storagePlace ?? FoodFacts.storage(item.name))
        .trim()
        .toLowerCase();
    if (raw == 'fridge') return 'Fridge';
    if (raw == 'freezer') return 'Freezer';
    return 'Pantry';
  }

  Widget _summaryCards(List<PantryIngredient> expiring) {
    final value = expiring.fold<double>(
      0,
      (sum, item) => sum + item.quantityRemaining * item.estimatedUnitValueGbp,
    );
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '${expiring.length}',
            label: 'Expiring soon',
            valueColor: AppColors.roseText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '£${value.toStringAsFixed(0)}',
            label: 'At risk this week',
            valueColor: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _placeChips() {
    const places = ['All items', 'Fridge', 'Freezer', 'Pantry'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final place in places) ...[
            GestureDetector(
              onTap: () => setState(() => _place = place),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _place == place ? AppColors.forest : AppColors.surface,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  place,
                  style: AppText.caption(
                    color: _place == place ? AppColors.surface : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<PantryIngredient> items, {
    bool selectable = true,
  }) {
    final visible = items.where((item) => !_binned.contains(item.id)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final tone = switch (title) {
      'Expired' => AppColors.error,
      'Expiring soon' => AppColors.muted,
      _ => AppColors.textMuted,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppText.title(fontSize: 18, color: AppColors.ink)),
              const Spacer(),
              Text(
                '${visible.length} ${visible.length == 1 ? 'item' : 'items'}',
                style: AppText.caption(color: tone, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...visible.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ValueKey('${item.id}-$title'),
                direction: selectable
                    ? DismissDirection.horizontal
                    : DismissDirection.endToStart,
                background: const _SwipeBg(
                  align: Alignment.centerLeft,
                  color: AppColors.sageSoft,
                  icon: Icons.restaurant,
                  label: 'Cook with this',
                ),
                secondaryBackground: const _SwipeBg(
                  align: Alignment.centerRight,
                  color: AppColors.roseSoft,
                  icon: Icons.delete_outline,
                  label: 'Used up / Bin',
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    if (ExpiryInfo.urgency(item) == ExpiryUrgency.expired) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Expired food cannot be cooked.'),
                        ),
                      );
                      return false;
                    }
                    _openCook(focus: [item.name]);
                    return false;
                  }
                  if (item.isAvailable) {
                    await state.editIngredient(
                      item.copyWith(quantityRemaining: 0),
                    );
                    return false;
                  }
                  return true;
                },
                onDismissed: (_) {
                  setState(() => _binned.add(item.id));
                  state.removeIngredient(item.id);
                },
                child: IngredientCard(
                  ingredient: item,
                  selected: _selected.contains(item.id),
                  soonDays: state.expirySoonDays,
                  onTap: selectable ? () => _toggle(item) : () => _edit(item),
                  onEdit: () => _edit(item),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _edit(PantryIngredient item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IngredientDetailScreen(ingredientId: item.id),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, AppState state) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: 'pcs');
    DateTime? expiry;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add ingredient', style: AppText.title()),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PantryImportScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Add from photos'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Or type one in', style: AppText.body(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Quantity'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(labelText: 'Unit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: DateTime.now().add(const Duration(days: 3)),
                      );
                      if (picked != null) setModal(() => expiry = picked);
                    },
                    child: Text(
                      expiry == null
                          ? 'Set expiry (optional)'
                          : 'Expires ${DateFormat.yMMMd().format(expiry!)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final qty = double.tryParse(qtyCtrl.text) ?? 1;
                        if (name.isEmpty) return;
                        await state.addIngredient(
                          name: name,
                          quantity: qty,
                          unit: unitCtrl.text.trim().isEmpty
                              ? 'pcs'
                              : unitCtrl.text.trim(),
                          expiry: expiry,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.display(fontSize: 28, color: valueColor)),
          const SizedBox(height: 4),
          Text(label, style: AppText.caption(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _CookPill extends StatelessWidget {
  const _CookPill({
    required this.label,
    required this.onPressed,
    this.useSoon = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool useSoon;

  @override
  Widget build(BuildContext context) {
    final fill = useSoon ? AppColors.sageSoft : AppColors.forest;
    final ink = useSoon ? AppColors.forest : Colors.white;
    return Material(
      color: fill,
      elevation: useSoon ? 1 : 6,
      shadowColor: const Color(0x4D2E6B4E),
      shape: StadiumBorder(
        side: useSoon
            ? const BorderSide(color: AppColors.sageBorder, width: 1.4)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (useSoon) ...[
                Icon(Icons.schedule_rounded, size: 18, color: ink),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.button(color: ink, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.align,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment align;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.ink),
          const SizedBox(width: 6),
          Text(label, style: AppText.label(fontSize: 13)),
        ],
      ),
    );
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (state.savedRecipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'Tap the heart on a recipe to save it here.',
            textAlign: TextAlign.center,
            style: AppText.body(),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, kFloatingNavClearance),
      itemCount: state.savedRecipes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final recipe = state.savedRecipes[index];
        return RecipeGridCard(
          recipe: recipe,
          isSaved: true,
          onHeart: () => state.toggleSave(recipe),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: recipe),
              ),
            );
          },
        );
      },
    );
  }
}
