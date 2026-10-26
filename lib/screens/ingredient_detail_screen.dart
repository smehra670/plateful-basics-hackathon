import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/expiry.dart';
import '../widgets/expiry_badge.dart';
import '../widgets/pantry_photo.dart';
import 'recipe_detail_screen.dart';

class IngredientDetailScreen extends StatefulWidget {
  const IngredientDetailScreen({super.key, required this.ingredientId});

  final String ingredientId;

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  List<IngredientUsageEvent> usage = [];
  List<Recipe> recipes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final u = await state.usageFor(widget.ingredientId);
    final r = await state.recipesForIngredient(widget.ingredientId);
    if (!mounted) return;
    setState(() {
      usage = u;
      recipes = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    PantryIngredient? ingredient;
    for (final i in state.ingredients) {
      if (i.id == widget.ingredientId) {
        ingredient = i;
        break;
      }
    }

    if (ingredient == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Ingredient not found')),
      );
    }

    final item = ingredient;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(item.name, style: AppText.title(fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () async {
              await state.removeIngredient(item.id);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: PantryPhoto(path: item.imageUrl),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ExpiryBadge(
              ingredient: item,
              soonDays: state.expirySoonDays,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Quantity remaining', style: AppText.body()),
                    ),
                    IconButton(
                      onPressed: item.quantityRemaining <= 0
                          ? null
                          : () => state.editIngredient(
                                item.copyWith(
                                  quantityRemaining:
                                      (item.quantityRemaining - 1)
                                          .clamp(0, 9999),
                                ),
                              ),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${_fmt(item.quantityRemaining)} ${item.unit}',
                      style: AppText.label(),
                    ),
                    IconButton(
                      onPressed: () => state.editIngredient(
                        item.copyWith(
                          quantityRemaining: item.quantityRemaining + 1,
                        ),
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                _row('Total consumed',
                    '${_fmt(item.totalQuantityUsed)} ${item.unit}'),
                _row('Times used', '${item.timesUsed}'),
                _row(
                  'Expiry',
                  item.expiryDate == null
                      ? 'Not set'
                      : '${DateFormat.yMMMd().format(item.expiryDate!)} · ${ExpiryInfo.label(item)}',
                ),
                _row('Stored in', item.storagePlace ?? 'Not set'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _editQuantity(context, state, item),
                  child: const Text('Edit quantity'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _editExpiry(context, state, item),
                  child: const Text('Edit expiry'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _editName(context, state, item),
                  child: const Text('Edit name'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _editPlace(context, state, item),
                  child: const Text('Edit place'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Usage history', style: AppText.title(fontSize: 18)),
          const SizedBox(height: 10),
          if (usage.isEmpty)
            Text('No usage yet.', style: AppText.body())
          else
            ...usage.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${_fmt(e.quantityUsed)} ${e.unit} used',
                  style: AppText.label(),
                ),
                subtitle: Text(
                  DateFormat.yMMMd().add_jm().format(e.timestamp),
                  style: AppText.body(fontSize: 12),
                ),
                trailing: e.wasNearExpiry
                    ? Text('Use Soon',
                        style: AppText.label(color: AppColors.accent, fontSize: 11))
                    : null,
              ),
            ),
          const SizedBox(height: 20),
          Text('Cooked with this', style: AppText.title(fontSize: 18)),
          const SizedBox(height: 10),
          if (recipes.isEmpty)
            Text('No cooked recipes yet.', style: AppText.body())
          else
            ...recipes.map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.title, style: AppText.label()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipe: r),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body())),
          Text(value, style: AppText.label()),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Future<void> _editQuantity(
    BuildContext context,
    AppState state,
    PantryIngredient item,
  ) async {
    final ctrl =
        TextEditingController(text: item.quantityRemaining.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit quantity'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: item.unit),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(ctrl.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await state.editIngredient(
      item.copyWith(quantityRemaining: result < 0 ? 0 : result),
    );
  }

  Future<void> _editExpiry(
    BuildContext context,
    AppState state,
    PantryIngredient item,
  ) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: item.expiryDate ?? DateTime.now().add(const Duration(days: 3)),
    );
    if (picked == null) return;
    await state.editIngredient(item.copyWith(expiryDate: picked));
  }

  Future<void> _editName(
    BuildContext context,
    AppState state,
    PantryIngredient item,
  ) async {
    final ctrl = TextEditingController(text: item.name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.sentences,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await state.editIngredient(item.copyWith(name: result));
  }

  Future<void> _editPlace(
    BuildContext context,
    AppState state,
    PantryIngredient item,
  ) async {
    const places = ['Fridge', 'Freezer', 'Cupboard', 'Counter'];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: places
              .map(
                (place) => ListTile(
                  title: Text(place),
                  onTap: () => Navigator.pop(ctx, place),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked == null) return;
    await state.editIngredient(item.copyWith(storagePlace: picked));
  }
}
