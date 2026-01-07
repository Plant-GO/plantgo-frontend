import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/level.dart';

/// Widget representing a level node on the course map
/// Shows different states: locked, active, completed with stars
class LevelNode extends StatelessWidget {
  final Level level;
  final VoidCallback? onTap;
  final double size;

  const LevelNode({super.key, required this.level, this.onTap, this.size = 70});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: level.isPlayable ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNode(),
          if (level.status == LevelStatus.completed) _buildStars(),
          const SizedBox(height: 4),
          Text(
            level.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: level.status == LevelStatus.locked
                  ? AppColors.textTertiary
                  : AppColors.textPrimary,
            ),
          ),
          if (level.subtitle.isNotEmpty && level.status == LevelStatus.active)
            Text(
              '"${level.subtitle}"',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNode() {
    switch (level.status) {
      case LevelStatus.locked:
        return _buildLockedNode();
      case LevelStatus.active:
        return _buildActiveNode();
      case LevelStatus.completed:
        return _buildCompletedNode();
    }
  }

  Widget _buildLockedNode() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.levelLocked, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.lock_rounded,
          color: AppColors.levelLocked,
          size: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildActiveNode() {
    return Container(
      width: size + 10,
      height: size + 10,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildCompletedNode() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.check_rounded,
          color: AppColors.success,
          size: size * 0.45,
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final isEarned = index < level.stars;
          return Icon(
            Icons.star_rounded,
            size: 16,
            color: isEarned ? AppColors.secondary : AppColors.levelLocked,
          );
        }),
      ),
    );
  }
}
