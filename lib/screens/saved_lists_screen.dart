import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/pill_button.dart';
import '../widgets/recipe_card.dart';

class SavedListsScreen extends StatefulWidget {
  const SavedListsScreen({super.key});

  @override
  State<SavedListsScreen> createState() => _SavedListsScreenState();
}

class _SavedListsScreenState extends State<SavedListsScreen> {
  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = SampleData.savedLists.map((e) => e.done).toList();
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dates = [10, 11, 12, 13, 14, 15, 16];
    const selected = 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          'Saved',
          style: AppText.display(fontSize: 32, color: AppColors.forest),
        ),
        const SizedBox(height: 6),
        Text(
          'Your lists and meals, ready when you need them.',
          style: AppText.body(fontSize: 14),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isSelected = index == selected;
              return Container(
                width: 52,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.forest : AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? AppColors.forest : AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      days[index],
                      style: AppText.label(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? AppColors.sage : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dates[index]}',
                      style: AppText.label(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Your lists', style: AppText.title()),
            const Spacer(),
            Text(
              '${_checked.where((e) => !e).length} open',
              style: AppText.label(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(SampleData.savedLists.length, (index) {
          final item = SampleData.savedLists[index];
          final done = _checked[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() => _checked[index] = !_checked[index]),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? AppColors.forest : Colors.transparent,
                          border: Border.all(
                            color: done ? AppColors.forest : AppColors.textMuted,
                            width: 1.5,
                          ),
                        ),
                        child: done
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppText.label(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ).copyWith(
                                decoration:
                                    done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.subtitle} · ${item.items} items',
                              style: AppText.body(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        PillButton(
          label: 'Create new list',
          filled: false,
          icon: Icons.add_rounded,
          onPressed: () {},
        ),
        const SizedBox(height: 28),
        Text('Saved recipes', style: AppText.title()),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: SampleData.recipes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            return RecipeGridCard(recipe: SampleData.recipes[index]);
          },
        ),
      ],
    );
  }
}
