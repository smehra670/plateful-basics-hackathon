import 'package:flutter/material.dart';

/// Plate + fork glyph so the planner tab reads as meals, not a gym week view.
class PlannerIcon extends StatelessWidget {
  const PlannerIcon({
    super.key,
    required this.color,
    this.size = 26,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlannerIconPainter(color: color),
      ),
    );
  }
}

class _PlannerIconPainter extends CustomPainter {
  _PlannerIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width * 0.42;
    final cy = size.height * 0.52;
    final r = size.width * 0.34;
    canvas.drawCircle(Offset(cx, cy), r, stroke);
    canvas.drawCircle(Offset(cx, cy), r * 0.55, stroke);

    final forkX = size.width * 0.82;
    final top = size.height * 0.18;
    final mid = size.height * 0.48;
    final bot = size.height * 0.86;
    final spread = size.width * 0.07;
    canvas.drawLine(Offset(forkX - spread, top), Offset(forkX - spread, mid), stroke);
    canvas.drawLine(Offset(forkX, top), Offset(forkX, mid), stroke);
    canvas.drawLine(Offset(forkX + spread, top), Offset(forkX + spread, mid), stroke);
    canvas.drawLine(Offset(forkX - spread, mid), Offset(forkX + spread, mid), stroke);
    canvas.drawLine(Offset(forkX, mid), Offset(forkX, bot), stroke);
  }

  @override
  bool shouldRepaint(covariant _PlannerIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
