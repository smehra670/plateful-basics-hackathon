import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CalorieSegment {
  const CalorieSegment({
    required this.label,
    required this.kcal,
    required this.eaten,
  });

  final String label;
  final int kcal;
  final bool eaten;
}

class SegmentedCalorieBar extends StatelessWidget {
  const SegmentedCalorieBar({super.key, required this.segments});

  final List<CalorieSegment> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                flex: segments[i].kcal <= 0 ? 1 : segments[i].kcal,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  height: 10,
                  decoration: BoxDecoration(
                    color: segments[i].eaten
                        ? AppColors.forest
                        : AppColors.sageTrack,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                flex: segments[i].kcal <= 0 ? 1 : segments[i].kcal,
                child: Text(
                  segments[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption(
                    fontSize: 12,
                    color: segments[i].eaten
                        ? AppColors.forest
                        : AppColors.muted,
                  ).copyWith(
                    fontWeight: segments[i].eaten
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
