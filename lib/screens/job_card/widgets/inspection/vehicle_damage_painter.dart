import 'package:flutter/material.dart';

class VehicleDamagePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  const VehicleDamagePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final damagePaint = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final points in strokes) {
      if (points.isEmpty) continue;
      final damage = Path()..moveTo(points.first.dx * w, points.first.dy * h);
      for (final point in points.skip(1)) {
        damage.lineTo(point.dx * w, point.dy * h);
      }
      if (points.length == 1) {
        canvas.drawCircle(
          Offset(points.first.dx * w, points.first.dy * h),
          4,
          damagePaint,
        );
      } else {
        canvas.drawPath(damage, damagePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant VehicleDamagePainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}
