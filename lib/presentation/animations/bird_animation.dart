import 'package:flutter/material.dart';
import 'package:plantgo/core/constants/app_images.dart';
import 'dart:math' as math;

/// Bird flock animation that moves horizontally across the screen
class BirdFlockAnimation extends StatefulWidget {
  final double? top;
  final double duration;
  final double birdSize;
  
  const BirdFlockAnimation({
    Key? key,
    this.top = 60,
    this.duration = 14.0, // Time to cross screen in seconds
    this.birdSize = 200,
  }) : super(key: key);

  @override
  State<BirdFlockAnimation> createState() => _BirdFlockAnimationState();
}

class _BirdFlockAnimationState extends State<BirdFlockAnimation>
    with TickerProviderStateMixin {
  late AnimationController _flockController;
  late Animation<double> _flockAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFlockAnimations();
  }

  void _initializeFlockAnimations() {
    // Horizontal movement animation
    _flockController = AnimationController(
      duration: Duration(seconds: widget.duration.toInt()),
      vsync: this,
    );

    _flockAnimation = Tween<double>(
      begin: -1.2, // Start off-screen left
      end: 1.2,    // End off-screen right
    ).animate(CurvedAnimation(
      parent: _flockController,
      curve: Curves.linear,
    ));

    // Start animation and repeat
    _startFlockAnimation();
  }

  void _startFlockAnimation() {
    _flockController.forward().then((_) {
      // Wait a bit before next flock
      Future.delayed(Duration(seconds: 5 + math.Random().nextInt(6)), () {
        if (mounted) {
          _flockController.reset();
          _startFlockAnimation();
        }
      });
    });
  }

  @override
  void dispose() {
    _flockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      child: AnimatedBuilder(
        animation: _flockController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _flockAnimation.value * MediaQuery.of(context).size.width,
              // Add slight vertical movement for natural flight
              10 * math.sin(_flockAnimation.value * 4 * math.pi),
            ),
            child: Image.asset(
              AppImages.birds1, // Use birds1 for flock
              width: widget.birdSize,
              height: widget.birdSize * 0.6,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}

/// Single flying bird with simple drifting animation
class FlyingBirdAnimation extends StatefulWidget {
  final double? top;
  final double? left;
  final double? right;
  final double birdSize;
  final double floatDuration;

  const FlyingBirdAnimation({
    Key? key,
    this.top = 150,
    this.left,
    this.right,
    this.birdSize = 40,
    this.floatDuration = 10.0,
  }) : super(key: key);

  @override
  State<FlyingBirdAnimation> createState() => _FlyingBirdAnimationState();
}

class _FlyingBirdAnimationState extends State<FlyingBirdAnimation> with TickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: Duration(milliseconds: (widget.floatDuration * 1000).toInt()),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine positioning: if neither left nor right provided, default left to 0
    double? leftPos = widget.left;
    double? rightPos = widget.right;
    if (leftPos == null && rightPos == null) leftPos = 0;
    return Positioned(
      top: widget.top,
      left: leftPos,
      right: rightPos,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final totalWidth = MediaQuery.of(context).size.width - (widget.left ?? 0);
          final dx = _floatController.value * totalWidth; // horizontal drift left to right
          final dy = 15 * math.sin(_floatController.value * 2 * math.pi); // subtle vertical float
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Image.asset(
              AppImages.birds2, // Single bird using birds2
              width: widget.birdSize,
              height: widget.birdSize * 0.8,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
