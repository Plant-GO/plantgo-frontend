// lib/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:plantgo/utils/app_colors.dart'; // Assuming AppColors is in utils

class ExploreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ExploreScreen is now a placeholder
    return Scaffold(
      appBar: AppBar(
        title: Text("Explore", style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.darkBlue2,
      ),
      body: Center(
        child: Text(
          "Explore Page - Content Coming Soon!",
          style: TextStyle(fontSize: 18, color: AppColors.textLight, fontFamily: 'Nunito'),
        ),
      ),
      backgroundColor: AppColors.background,
    );
  }
}
