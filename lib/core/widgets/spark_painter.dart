import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Draws the white contact spark (same geometry as the SVG logo) and an
/// expanding red → blue shockwave ring, centred in the canvas.
///
/// Geometry is expressed in the logo's 512-unit space; [unit] converts it to
/// logical pixels (canvas width / 512 when the canvas matches the logo).
class SparkPainter extends CustomPainter {
  SparkPainter({
    required this.unit,
    required this.sparkScale,
    this.sparkOpacity = 1,
    this.ringProgress = 0,
    this.ringOpacity = 0,
  });

  final double unit;
  final double sparkScale;
  final double sparkOpacity;
  final double ringProgress;
  final double ringOpacity;

  static const double _outer = 70;
  static const double _mid = 52;
  static const double _inner = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    if (ringOpacity > 0 && ringProgress > 0) {
      final radius = (40 + 200 * ringProgress) * unit;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, 14 * (1 - ringProgress)) * unit
        ..shader = AppColors.gradient.createShader(rect);
      canvas.saveLayer(rect.inflate(20 * unit), Paint()..color = Colors.white.withValues(alpha: ringOpacity.clamp(0, 1)));
      canvas.drawCircle(center, radius, ring);
      canvas.restore();
    }

    if (sparkScale <= 0 || sparkOpacity <= 0) return;

    final path = Path();
    for (var i = 0; i < 16; i++) {
      final angle = -math.pi / 2 + i * math.pi / 8;
      final r = i.isOdd ? _inner : (i % 4 == 0 ? _outer : _mid);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r * unit * sparkScale;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final fill = Paint()..color = Colors.white.withValues(alpha: sparkOpacity.clamp(0, 1));
    canvas.drawPath(path, fill);

    // Two flying shards, like the logo.
    final shard = Paint()
      ..color = Colors.white.withValues(alpha: sparkOpacity.clamp(0, 1))
      ..strokeWidth = 8 * unit * sparkScale
      ..strokeCap = StrokeCap.round;
    final reach = 92 * unit * sparkScale;
    final length = 26 * unit * sparkScale;
    canvas.drawLine(center + Offset(0, -reach), center + Offset(0, -reach - length), shard);
    canvas.drawLine(center + Offset(0, reach), center + Offset(0, reach + length), shard);
  }

  @override
  bool shouldRepaint(SparkPainter oldDelegate) =>
      oldDelegate.unit != unit ||
      oldDelegate.sparkScale != sparkScale ||
      oldDelegate.sparkOpacity != sparkOpacity ||
      oldDelegate.ringProgress != ringProgress ||
      oldDelegate.ringOpacity != ringOpacity;
}
