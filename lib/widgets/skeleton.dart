import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.45 + (_controller.value * 0.4),
          child: child,
        );
      },
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.creamDark,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class RecipeSkeleton extends StatelessWidget {
  const RecipeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(flex: 6, child: SkeletonBox(radius: 28)),
          SizedBox(height: 16),
          SkeletonBox(height: 22, width: 220),
          SizedBox(height: 10),
          SkeletonBox(height: 14, width: 280),
          SizedBox(height: 10),
          SkeletonBox(height: 14, width: 180),
        ],
      ),
    );
  }
}
