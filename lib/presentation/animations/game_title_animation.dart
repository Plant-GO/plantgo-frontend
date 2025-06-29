import 'package:flutter/material.dart';
import 'package:plantgo/configs/app_colors.dart';
import 'package:plantgo/core/constants/app_images.dart';
import 'dart:math' as math;

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
  late Animation<double> _shimmerAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _swayAnimation;

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

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Bounce animation - Candy Crush logo bounce
    _bounceController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticInOut,
    ));

    // Glow animation - pulsing glow effect
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Pulse scale animation - makes logo grow and shrink
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Sway animation - gentle left-right movement
    _swayController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _swayAnimation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(
      parent: _swayController,
      curve: Curves.easeInOut,
    ));

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
