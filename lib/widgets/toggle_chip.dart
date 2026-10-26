import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/app_theme.dart';
import 'pressable.dart';

enum ToggleChipVariant { danger, solid, soft }

class ToggleChip extends StatelessWidget {
  const ToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.variant = ToggleChipVariant.solid,
    this.onRemove,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ToggleChipVariant variant;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(selected, variant);
    return Pressable(
      onTap: onRemove ?? onTap,
      toggled: selected,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (colors.icon != null) ...[
              Icon(colors.icon, size: 14, color: colors.foreground),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppText.label(color: colors.foreground, fontSize: 14),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              Icon(PhosphorIconsRegular.x, size: 14, color: colors.foreground),
            ],
          ],
        ),
      ),
    );
  }

  _ChipColors _colors(bool on, ToggleChipVariant variant) {
    switch (variant) {
      case ToggleChipVariant.danger:
        if (!on) {
          return const _ChipColors(
            background: AppColors.ground,
            border: Colors.transparent,
            foreground: AppColors.chipText,
          );
        }
        return const _ChipColors(
          background: AppColors.roseSoft,
          border: AppColors.roseBorder,
          foreground: AppColors.roseText,
          icon: PhosphorIconsRegular.prohibit,
        );
      case ToggleChipVariant.solid:
        if (!on) {
          return const _ChipColors(
            background: AppColors.ground,
            border: Colors.transparent,
            foreground: AppColors.chipText,
          );
        }
        return const _ChipColors(
          background: AppColors.forest,
          border: AppColors.forest,
          foreground: Colors.white,
          icon: PhosphorIconsRegular.check,
        );
      case ToggleChipVariant.soft:
        if (!on) {
          return const _ChipColors(
            background: AppColors.ground,
            border: Colors.transparent,
            foreground: AppColors.chipText,
          );
        }
        return const _ChipColors(
          background: AppColors.sageSoft,
          border: AppColors.sageBorder,
          foreground: AppColors.forest,
          icon: PhosphorIconsRegular.heart,
        );
    }
  }
}

class _ChipColors {
  const _ChipColors({
    required this.background,
    required this.border,
    required this.foreground,
    this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData? icon;
}
