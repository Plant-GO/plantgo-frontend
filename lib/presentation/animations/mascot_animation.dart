import 'package:flutter/material.dart';
import 'package:plantgo/core/constants/app_images.dart';

class MascotAnimation extends StatefulWidget {
  final double? width;
  final double? height;
  final double? bottom;
  final double? left;

  const MascotAnimation({
    Key? key,
    this.width = 180,
    this.height = 300,
    this.bottom = 30,
    this.left = 4,
  }) : super(key: key);

  @override
  State<MascotAnimation> createState() => _MascotAnimationState();
}

class _MascotAnimationState extends State<MascotAnimation>
    with TickerProviderStateMixin {
  late AnimationController _characterAnimationController;
  late Animation<double> _characterBounce;

  @override
  void initState() {
    super.initState();
    _initializeCharacterAnimations();
  }

  void _initializeCharacterAnimations() {
    // Character bounce animation
    _characterAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _characterBounce = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _characterAnimationController,
      curve: Curves.elasticInOut,
    ));

    // Start animation
    _characterAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _characterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: widget.bottom,
      left: widget.left,
      child: AnimatedBuilder(
        animation: _characterAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _characterBounce.value),
            child: Image.asset(
              AppImages.mascots,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
