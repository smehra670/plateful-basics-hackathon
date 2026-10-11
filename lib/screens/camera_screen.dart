import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/pill_button.dart';
import '../widgets/recipe_card.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          'Scan',
          style: AppText.display(fontSize: 32, color: AppColors.forest),
        ),
        const SizedBox(height: 6),
        Text(
          'Snap leftovers or labels — Plateful will help you use them up.',
          style: AppText.body(fontSize: 14),
        ),
        const SizedBox(height: 22),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: AppColors.creamDark,
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=900&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: AppColors.sage),
                ),
                Container(color: Colors.black.withValues(alpha: 0.18)),
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Column(
                    children: [
                      Text(
                        'Align food in the frame',
                        style: AppText.label(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.sage, width: 4),
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          color: AppColors.forest,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        PillButton(
          label: 'Open camera',
          icon: Icons.photo_camera_outlined,
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        PillButton(
          label: 'Upload from gallery',
          filled: false,
          icon: Icons.image_outlined,
          onPressed: () {},
        ),
        const SizedBox(height: 28),
        Text('Ideas from recent scans', style: AppText.title()),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: SampleData.recipes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 150,
                child: RecipeGridCard(recipe: SampleData.recipes[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
