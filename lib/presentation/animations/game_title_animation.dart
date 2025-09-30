import 'package:flutter/material.dart';
import 'package:plantgo/core/constants/app_images.dart';

class GameTitleAnimation extends StatefulWidget {
  final String title;
  final double? imageWidth;
  final double? imageHeight;
  final String fontFamily;
  final double? top;
  final double? bottom;
  final EdgeInsetsGeometry? padding;

  const GameTitleAnimation({
    Key? key,
    this.title = 'PlantGo',
    this.imageWidth = 300,
    this.imageHeight = 150,
    this.fontFamily = 'Poppins',
    this.top,
    this.bottom,
    this.padding,
  }) : super(key: key);

  @override
  State<GameTitleAnimation> createState() => _GameTitleAnimationState();
}

class _GameTitleAnimationState extends State<GameTitleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _swayController;

  @override
  void initState() {
    super.initState();
    _initializeTitleAnimations();
  }

  void _initializeTitleAnimations() {
    // Shimmer effect animation - Candy Crush style shine
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Bounce animation - Candy Crush logo bounce
    _bounceController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Glow animation - pulsing glow effect
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Pulse scale animation - makes logo grow and shrink
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Sway animation - gentle left-right movement
    _swayController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    // Start animations with staggered timing
    _bounceController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _glowController.repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _pulseController.repeat(reverse: true);
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _shimmerController.repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _swayController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _swayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      bottom: widget.bottom,
      left: 0,
      right: 0,
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 20),
        child: Image.asset(
          AppImages.plantgo,
          width: widget.imageWidth,
          height: widget.imageHeight,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
