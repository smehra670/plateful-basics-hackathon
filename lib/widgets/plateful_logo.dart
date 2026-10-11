import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Plateful wordmark with leaf accent (from brand asset).
class PlatefulLogo extends StatelessWidget {
  const PlatefulLogo({
    super.key,
    this.height = 36,
    this.color = AppColors.forest,
  });

  final double height;
  final Color color;

  static const assetPath = 'assets/images/plateful_logo.png';

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: Image.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'plateful',
      ),
    );
  }
}
