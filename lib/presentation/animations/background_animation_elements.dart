import 'package:flutter/material.dart';
import 'package:plantgo/presentation/animations/cloud_animation.dart';
import 'package:plantgo/presentation/animations/bird_animation.dart';

class BackgroundAnimationElements extends StatelessWidget {
  const BackgroundAnimationElements({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Cloud animations
        const CloudAnimation(),
        // Bird flock animation
        const BirdFlockAnimation(
          top: 100,
          duration: 8.0,
          birdSize: 60,
        ),
        // Flying bird animation
        const FlyingBirdAnimation(
          top: 180,
          right: 60,
          birdSize: 35,
        ),
      ],
    );
  }
}
