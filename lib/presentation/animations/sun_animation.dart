import 'package:flutter/material.dart';
import 'dart:math' as math;

class SunGlitterAnimation extends StatefulWidget {
  final double? top;
  final double? left;
  final double? right;
  final double glitterAreaSize;
  final Color glitterColor;
  final int sparkleCount;

  const SunGlitterAnimation({
    Key? key,
    this.top = 120, // Position to match the sun in background
    this.left,
    this.right = 30, // Position from right to match the sun
    this.glitterAreaSize = 150, // Area around the sun for sparkles
    this.glitterColor = const Color(0xFFFFD700),
    this.sparkleCount = 8, // Number of sparkles around sun
  }) : super(key: key);

  @override
  State<SunGlitterAnimation> createState() => _SunGlitterAnimationState();
}

class _SunGlitterAnimationState extends State<SunGlitterAnimation>
    with TickerProviderStateMixin {
  late AnimationController _glitterController;
  late Animation<double> _glitterAnimation;
  late List<SparkleData> _sparkles;

  @override
  void initState() {
    super.initState();
    _initializeGlitterAnimations();
    _generateSparkles();
  }

  void _initializeGlitterAnimations() {
    // Twinkling animation for sparkles around the sun
    _glitterController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _glitterAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _glitterController,
      curve: Curves.easeInOut,
    ));

    // Start animation
    _glitterController.repeat();
  }

  void _generateSparkles() {
    _sparkles = List.generate(widget.sparkleCount, (index) {
      return SparkleData(
        angle: (index * 2 * math.pi / widget.sparkleCount),
        distance: 60 + (index % 3) * 15, // Varying distances from sun
        phase: (index * 0.2), // Different twinkling phases
        size: 2.0 + (index % 3), // Different sizes
      );
    });
  }

  @override
  void dispose() {
    _glitterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      right: widget.right,
      child: AnimatedBuilder(
        animation: _glitterController,
        builder: (context, child) {
          return SizedBox(
            width: widget.glitterAreaSize,
            height: widget.glitterAreaSize,
            child: CustomPaint(
              painter: SunGlitterPainter(
                animationValue: _glitterAnimation.value,
                glitterColor: widget.glitterColor,
                sparkles: _sparkles,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Data class for sparkle information
class SparkleData {
  final double angle;
  final double distance;
  final double phase;
  final double size;

  SparkleData({
    required this.angle,
    required this.distance,
    required this.phase,
    required this.size,
  });
}

class SunGlitterPainter extends CustomPainter {
  final double animationValue;
  final Color glitterColor;
  final List<SparkleData> sparkles;

  SunGlitterPainter({
    required this.animationValue,
    required this.glitterColor,
    required this.sparkles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw twinkling sparkles around the existing sun
    _drawSparkles(canvas, center);
  }

  void _drawSparkles(Canvas canvas, Offset center) {
    for (int i = 0; i < sparkles.length; i++) {
      final sparkle = sparkles[i];
      
      // Calculate sparkle position
      final sparkleX = center.dx + sparkle.distance * math.cos(sparkle.angle);
      final sparkleY = center.dy + sparkle.distance * math.sin(sparkle.angle);
      final sparkleCenter = Offset(sparkleX, sparkleY);
      
      // Calculate twinkling opacity with phase offset
      final twinklePhase = (animationValue + sparkle.phase) % 1.0;
      final opacity = 0.3 + 0.7 * (math.sin(twinklePhase * 2 * math.pi) * 0.5 + 0.5);
      
      // Create sparkle paint with twinkling opacity
      final sparklePaint = Paint()
        ..color = glitterColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      // Draw different sparkle shapes
      if (i % 3 == 0) {
        _drawStarSparkle(canvas, sparkleCenter, sparkle.size, sparklePaint);
      } else if (i % 3 == 1) {
        _drawDiamondSparkle(canvas, sparkleCenter, sparkle.size, sparklePaint);
      } else {
        _drawCircleSparkle(canvas, sparkleCenter, sparkle.size, sparklePaint);
      }
    }
  }

  void _drawStarSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw a star-shaped sparkle
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final outerPoint = Offset(
        center.dx + size * math.cos(angle),
        center.dy + size * math.sin(angle),
      );
      
      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }
      
      // Add inner point
      final innerAngle = angle + math.pi / 4;
      final innerPoint = Offset(
        center.dx + size * 0.4 * math.cos(innerAngle),
        center.dy + size * 0.4 * math.sin(innerAngle),
      );
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawDiamondSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw a diamond-shaped sparkle
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.7, center.dy);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.7, center.dy);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawCircleSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw a simple circular sparkle
    canvas.drawCircle(center, size * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
