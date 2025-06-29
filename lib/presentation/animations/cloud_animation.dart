import 'package:flutter/material.dart';
import 'package:plantgo/core/constants/app_images.dart';

class CloudAnimation extends StatefulWidget {
  const CloudAnimation({Key? key}) : super(key: key);

  @override
  State<CloudAnimation> createState() => _CloudAnimationState();
}

class _CloudAnimationState extends State<CloudAnimation>
    with TickerProviderStateMixin {
  late AnimationController _cloudAnimationController;
  late Animation<Offset> _cloudAnimation1;
  late Animation<Offset> _cloudAnimation2;

  @override
  void initState() {
    super.initState();
    _initializeCloudAnimations();
  }

  void _initializeCloudAnimations() {
    // Cloud floating animation
    _cloudAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _cloudAnimation1 = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: const Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _cloudAnimationController,
      curve: Curves.easeInOut,
    ));

    // Floating cloud 2 animation
    _cloudAnimation2 = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: const Offset(-0.1, 0),
    ).animate(CurvedAnimation(
      parent: _cloudAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _cloudAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _cloudAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _cloudAnimationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Floating cloud 1
              Positioned(
                top: 100,
                left: 10,
                child: SlideTransition(
                  position: _cloudAnimation1,
                  child: Image.asset(
                    AppImages.clouds,
                    width: 160,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Floating cloud 2
              Positioned(
                top: 180,
                right: 0,
                child: SlideTransition(
                  position: _cloudAnimation2,
                  child: Image.asset(
                    AppImages.clouds,
                    width: 80,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
