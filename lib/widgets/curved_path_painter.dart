import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Custom painter for the curved dashed path between levels
class CurvedPathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  CurvedPathPainter({
    required this.points,
    this.color = AppColors.primary,
    this.strokeWidth = 3,
    this.dashLength = 8,
    this.dashGap = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // Create smooth curves through all points
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      // Calculate control points for smooth curve
      final controlX = (current.dx + next.dx) / 2;

      path.quadraticBezierTo(controlX, current.dy, next.dx, next.dy);
    }

    // Draw dashed path
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      bool draw = true;

      while (distance < metric.length) {
        final length = draw ? dashLength : dashGap;
        final end = (distance + length).clamp(0.0, metric.length);

        if (draw) {
          final extractPath = metric.extractPath(distance, end);
          canvas.drawPath(extractPath, paint);
        }

        distance = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CurvedPathPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

/// Widget that draws a curved path connecting level nodes
class LevelPathWidget extends StatelessWidget {
  final List<Offset> nodePositions;

  const LevelPathWidget({super.key, required this.nodePositions});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: CurvedPathPainter(points: nodePositions),
    );
  }
}
