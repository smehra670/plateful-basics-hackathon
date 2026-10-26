import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Press scale and a selection click for tappable controls.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.toggled,
    this.selected,
    this.scale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool? toggled;
  final bool? selected;
  final double scale;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _down = false;

  void _setDown(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && widget.onTap != null;
    return Semantics(
      button: true,
      enabled: canTap,
      label: widget.semanticLabel,
      toggled: widget.toggled,
      selected: widget.selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: canTap ? (_) => _setDown(true) : null,
        onTapUp: canTap ? (_) => _setDown(false) : null,
        onTapCancel: canTap ? () => _setDown(false) : null,
        onTap: canTap
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
