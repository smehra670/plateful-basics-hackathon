import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/category_chips.dart';
import '../widgets/plateful_logo.dart';
import '../widgets/recipe_card.dart';
import '../widgets/search_field.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PlatefulLogo(height: 28),
                const SizedBox(height: 18),
                Text('Ask AI', style: AppText.display(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  'Turn what you already have into something delicious.',
                  style: AppText.body(fontSize: 14),
                ),
                const SizedBox(height: 18),
                const SearchField(hint: 'Ingredients, cravings, leftovers…'),
                const SizedBox(height: 16),
                CategoryChips(
                  categories: SampleData.categories,
                  selected: _selectedCategory,
                  onSelected: (i) => setState(() => _selectedCategory = i),
                ),
                const SizedBox(height: 22),
                Text('Featured for you', style: AppText.title()),
                const SizedBox(height: 12),
                const FeaturedRecipeCard(recipe: SampleData.featured),
                const SizedBox(height: 22),
                Text('Try asking', style: AppText.title()),
                const SizedBox(height: 12),
                ...SampleData.prompts.map(
                  (prompt) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PromptChip(prompt: prompt),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Browse by goal', style: AppText.title()),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final goal = SampleData.goals[index];
                return _GoalTile(goal: goal);
              },
              childCount: SampleData.goals.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: AppColors.forest),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prompt,
              style: AppText.body(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final GoalCard goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: goal.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(goal.icon, size: 18, color: AppColors.forest),
          ),
          const Spacer(),
          Text(goal.title, style: AppText.title(fontSize: 17)),
          const SizedBox(height: 2),
          Text(goal.subtitle, style: AppText.body(fontSize: 12)),
        ],
      ),
    );
  }
}
