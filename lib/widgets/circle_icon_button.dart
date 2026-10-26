import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.iconColor = AppColors.ink,
    this.backgroundColor = AppColors.surface,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: semanticLabel,
      onTap: onTap,
      child: Tooltip(
        message: semanticLabel,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: AppShadows.chip,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
