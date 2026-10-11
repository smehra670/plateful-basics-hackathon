import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/impact_dashboard.dart';
import '../widgets/ingredient_card.dart';
import '../widgets/profile_avatar_button.dart';
import '../widgets/recipe_card.dart';
import 'ingredient_detail_screen.dart';
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
                  child: Text('My Pantry', style: AppText.display(fontSize: 28)),
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
                    label: 'Ingredients',
                    selected: _segment == 0,
                    onTap: () => setState(() => _segment = 0),
                  ),
                  _Seg(
                    label: 'Saved',
                    selected: _segment == 1,
                    onTap: () => setState(() => _segment = 1),
                  ),
                  _Seg(
                    label: 'My Impact',
                    selected: _segment == 2,
                    onTap: () => setState(() => _segment = 2),
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
              _ => ImpactDashboard(stats: state.impact),
            },
          ),
        ],
      ),
    );
  }
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
          padding: const EdgeInsets.symmetric(vertical: 10),
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

class _IngredientsTab extends StatelessWidget {
  const _IngredientsTab({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final available = state.availableIngredients;
    final used = state.previouslyUsedIngredients;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: available.isEmpty
                      ? null
                      : () {
                          state.setShellTab(0);
                          state.generateRecipesFromPantry();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text('Cook with my pantry', style: AppText.button()),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () => _showAddSheet(context, state),
                style: IconButton.styleFrom(backgroundColor: AppColors.sageMuted),
                icon: const Icon(Icons.add, color: AppColors.green),
              ),
            ],
          ),
        ),
        Expanded(
          child: available.isEmpty && used.isEmpty
              ? Center(
                  child: Text(
                    'Your pantry is empty. Scan or add ingredients.',
                    style: AppText.body(),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (available.isNotEmpty) ...[
                      Text('Available Ingredients', style: AppText.title(fontSize: 18)),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: available.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (context, i) {
                          final item = available[i];
                          return IngredientCard(
                            ingredient: item,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    IngredientDetailScreen(ingredientId: item.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (used.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Previously Used', style: AppText.title(fontSize: 18)),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: used.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (context, i) {
                          final item = used[i];
                          return IngredientCard(
                            ingredient: item,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    IngredientDetailScreen(ingredientId: item.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
        ),
      ],
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
                  const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
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
