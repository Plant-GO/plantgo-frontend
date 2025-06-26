import 'package:flutter/material.dart';
import 'package:plantgo/configs/app_colors.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Explore",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.darkBlue2,
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          "Explore Page - Content Coming Soon!",
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textLight,
            fontFamily: 'Nunito',
          ),
        ),
      ),
      backgroundColor: AppColors.background,
    );
  }
}
