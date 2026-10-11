import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class OrganicBackground extends StatelessWidget {
  const OrganicBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.cream)),
        Positioned(
          top: -80,
          right: -60,
          child: _Blob(
            size: 260,
            color: AppColors.peach.withValues(alpha: 0.55),
          ),
        ),
        Positioned(
          top: 120,
          left: -90,
          child: _Blob(
            size: 220,
            color: AppColors.sageBlob.withValues(alpha: 0.65),
          ),
        ),
        Positioned(
          bottom: 80,
          right: -40,
          child: _Blob(
            size: 180,
            color: AppColors.peachSoft.withValues(alpha: 0.7),
          ),
        ),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.45),
      ),
    );
  }
}
