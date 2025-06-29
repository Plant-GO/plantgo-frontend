import 'package:flutter/material.dart';

class StarAnimation extends StatefulWidget {
  final int starCount;
  final double startTop;
  final double startLeft;
  final double verticalSpacing;
  final double horizontalSpacing;

  const StarAnimation({
    Key? key,
    this.starCount = 8,
    this.startTop = 80,
    this.startLeft = 30,
    this.verticalSpacing = 50.0,
    this.horizontalSpacing = 120.0,
  }) : super(key: key);

  @override
  State<StarAnimation> createState() => _StarAnimationState();
}

class _StarAnimationState extends State<StarAnimation>
    with TickerProviderStateMixin {
  late AnimationController _starAnimationController;
  late List<Animation<double>> _starTwinkleAnimations;

  @override
  void initState() {
    super.initState();
    _initializeStarAnimations();
  }

  void _initializeStarAnimations() {
    // Star twinkling animation
    _starAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Create different twinkling animations for each star with different delays
    _starTwinkleAnimations = List.generate(widget.starCount, (index) {
      return Tween<double>(
        begin: 0.1,
        end: 0.8,
      ).animate(CurvedAnimation(
        parent: _starAnimationController,
        curve: Interval(
          (index * 0.125).clamp(0.0, 1.0), // Ensure interval is within bounds
          1.0,
          curve: Curves.easeInOut,
        ),
      ));
    });

    // Start animation
    _starAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _starAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _starAnimationController,
        builder: (context, child) {
          return Stack(
            children: List.generate(
              widget.starCount,
              (index) {
                // Safety check for animation list bounds
                if (index >= _starTwinkleAnimations.length) return const SizedBox.shrink();
                
                return Positioned(
                  top: widget.startTop + (index * widget.verticalSpacing),
                  left: widget.startLeft + (index % 3) * widget.horizontalSpacing,
                  child: AnimatedBuilder(
                    animation: _starTwinkleAnimations[index],
                    builder: (context, child) {
                      return Icon(
                        Icons.star,
                        color: Colors.white.withOpacity(_starTwinkleAnimations[index].value),
                        size: 12 + (index % 3) * 4,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
