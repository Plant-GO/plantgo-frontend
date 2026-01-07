import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/level.dart';
import '../providers/course_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/level_node.dart';
import '../widgets/stat_pill.dart';
import 'level_detail_screen.dart';
import 'dart:math' as math;

/// Course Map Screen - Level progression with curved path
/// Matches the design mockup with scrollable level path and swervy connections
class CourseMapScreen extends StatelessWidget {
  const CourseMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildStatRow(context),
            Expanded(child: _buildLevelPath(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Course Map',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(child: StatPill.coins(user.coins)),
          const SizedBox(width: 16),
          Expanded(child: StatPill.leaves(user.leaves)),
        ],
      ),
    );
  }

  Widget _buildLevelPath(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        debugPrint('🔄 CourseMapScreen: Building with ${courseProvider.levels.length} levels');
        
        if (courseProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        final levels = courseProvider.levels;
        final completedCount = levels.where((l) => l.status == LevelStatus.completed).length;
        debugPrint('✅ CourseMapScreen: $completedCount completed levels');

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return SingleChildScrollView(
          reverse: true, // Start from bottom (Level 1)
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: SizedBox(
            width: width,
            height: levels.length * 140.0 + 60,
            child: Stack(
              children: [
                // Decorative elements
                _buildDecorations(context),

                // Curved path connecting all levels
                CustomPaint(
                  size: Size(width, levels.length * 140.0 + 60),
                  painter: _CurvedPathPainter(
                    levelCount: levels.length,
                    levels: levels,
                    width: width,
                  ),
                ),

                // Level nodes
                ...List.generate(levels.length, (index) {
                  final level =
                      levels[levels.length -
                          1 -
                          index]; // Reverse for bottom-up
                  final reverseIndex = levels.length - 1 - index;

                  // Calculate positions to match the curved path
                  final isLeft = reverseIndex.isEven;
                  final xOffset = isLeft ? width * 0.25 : width * 0.75;
                  final yOffset = index * 140.0 + 40;

                  return Positioned(
                    left: xOffset - 45, // Center the node (node is ~90px wide)
                    top: yOffset,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (level.status == LevelStatus.active && !isLeft)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildBuddyIcon(),
                          ),
                        GestureDetector(
                          onTap: () => _openLevel(context, level),
                          child: LevelNode(level: level),
                        ),
                        if (level.status == LevelStatus.active && isLeft)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _buildBuddyIcon(),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
      },
    );
  }

  Widget _buildBuddyIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Center(child: Text('🦋', style: TextStyle(fontSize: 18))),
    );
  }

  Widget _buildDecorations(BuildContext context) {
    return Stack(
      children: [
        // Leaf decorations scattered around
        Positioned(
          left: 30,
          top: 80,
          child: Transform.rotate(
            angle: -0.2,
            child: Icon(
              Icons.eco_rounded,
              size: 28,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          right: 40,
          top: 180,
          child: Container(
            width: 45,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.levelLocked.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        Positioned(
          left: 25,
          top: 350,
          child: Transform.rotate(
            angle: 0.4,
            child: Icon(
              Icons.grass_rounded,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned(
          right: 35,
          top: 450,
          child: Icon(
            Icons.spa_rounded,
            size: 24,
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }

  void _openLevel(BuildContext context, Level level) {
    if (!level.isPlayable) return;

    context.read<CourseProvider>().selectLevel(level);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LevelDetailScreen()));
  }
}

/// Curved dashed path painter connecting level nodes with swervy lines
class _CurvedPathPainter extends CustomPainter {
  final int levelCount;
  final List<Level> levels;
  final double width;

  _CurvedPathPainter({
    required this.levelCount,
    required this.levels,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < levelCount - 1; i++) {
      final level = levels[levelCount - 1 - i];
      final nextLevel = levels[levelCount - 2 - i];

      final isActive =
          level.status != LevelStatus.locked &&
          nextLevel.status != LevelStatus.locked;

      final paint = Paint()
        ..color = (isActive ? AppColors.primary : AppColors.levelLocked)
            .withValues(alpha: 0.4)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final reverseIndex = levelCount - 1 - i;
      final nextReverseIndex = reverseIndex - 1;

      // Calculate start and end points
      final isStartLeft = reverseIndex.isEven;
      final isEndLeft = nextReverseIndex.isEven;

      final startX = isStartLeft ? width * 0.25 : width * 0.75;
      final startY = i * 140.0 + 90; // Below the node

      final endX = isEndLeft ? width * 0.25 : width * 0.75;
      final endY = (i + 1) * 140.0 + 40; // Above the next node

      // Create curved path
      final path = Path();
      path.moveTo(startX, startY);

      // Control points for smooth S-curve
      final controlY1 = startY + (endY - startY) * 0.4;
      final controlY2 = startY + (endY - startY) * 0.6;

      path.cubicTo(
        startX,
        controlY1, // First control point
        endX,
        controlY2, // Second control point
        endX,
        endY, // End point
      );

      // Draw dashed path
      _drawDashedPath(canvas, path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    const dashLength = 8.0;
    const dashGap = 6.0;

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
  bool shouldRepaint(covariant _CurvedPathPainter oldDelegate) {
    return oldDelegate.levelCount != levelCount || oldDelegate.width != width;
  }
}
