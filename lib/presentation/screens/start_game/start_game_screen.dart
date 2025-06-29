import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/configs/app_colors.dart';
import 'package:plantgo/configs/app_routes.dart';
import 'package:plantgo/presentation/blocs/start_game/start_game_cubit.dart';
import 'package:plantgo/presentation/blocs/start_game/start_game_state.dart';
import 'package:plantgo/presentation/screens/explore/explore_screen.dart';
import 'package:plantgo/presentation/screens/map/map_screen.dart';
import 'package:plantgo/presentation/screens/notifications/notifications_screen.dart';
import 'package:plantgo/presentation/screens/profile/profile_screen.dart';
import 'package:plantgo/presentation/blocs/map/map_cubit.dart';
import 'package:plantgo/presentation/blocs/profile/profile_cubit.dart';
import 'package:plantgo/presentation/animations/animations.dart';
import 'package:plantgo/core/constants/app_images.dart';
import 'package:plantgo/core/services/audio_service.dart';

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({super.key});

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
} 

class _StartGameScreenState extends State<StartGameScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildStartGameContent(),
      const ExploreScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
    context.read<StartGameCubit>().loadStartGameData();
    // Initialize BLoCs
    context.read<ProfileCubit>().loadProfile();
    // Play background music once user reaches start game screen
    AudioService.instance.playBackgroundMusic();
  }

  // Add safe animation wrapper
  Widget _buildSafeAnimationWrapper(Widget Function() animationBuilder) {
    try {
      return animationBuilder();
    } catch (e) {
      print('Animation error: $e');
      return const SizedBox.shrink(); // Return empty widget on error
    }
  }

  Widget _buildStartGameContent() {
    return BlocBuilder<StartGameCubit, StartGameState>(
      builder: (context, state) {
        return Column(
          children: [
            // Header with stats
            _buildHeader(state),
            // Main content area
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onMapButtonPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<MapCubit>(),
          child: const MapScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _selectedIndex == 0 
        ? Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  AppImages.startGame,
                  fit: BoxFit.cover,
                ),
              ),
              // Background animation elements - only clouds and birds
              const BackgroundAnimationElements(),
              // Header (coins & leaves) pinned to top
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BlocBuilder<StartGameCubit, StartGameState>(
                    builder: (context, state) => _buildHeader(state),
                  ),
                ),
              ),
              // PlantGo Title
              _buildSafeAnimationWrapper(() => GameTitleAnimation(
                title: 'PlantGo',
                imageWidth: 420,
                imageHeight: 300,
                top: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              )),
              // Flying bird animations
              const FlyingBirdAnimation(top: 240, left: 0, birdSize: 80 , floatDuration: 9,),
              const FlyingBirdAnimation(top: 280, right: 70, birdSize: 60, floatDuration: 12,),
              const FlyingBirdAnimation(top: 360, left: 0, birdSize: 80,floatDuration: 5,),
              const FlyingBirdAnimation(top: 280, left: 0, birdSize: 40,floatDuration: 4,),
              const FlyingBirdAnimation(top: 320, left: 0, birdSize: 50,floatDuration: 7,),
              // Main content
              Positioned(
                top: MediaQuery.of(context).padding.top + 140, // Start after title
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildMainContentWithoutTitle(),
              ),
            ],
          )
        : IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _onMapButtonPressed,
        backgroundColor: AppColors.primary,
        elevation: 4.0,
        shape: const CircleBorder(),
        child: Image.asset(
          'assets/icons/map.png',
          width: 40,
          height: 48,
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader(StartGameState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Coins
            _buildStatContainer(
              icon: Icons.monetization_on,
              value: state is StartGameLoaded ? state.coins.toString() : '0',
              color: AppColors.bee,
            ),
            // Experience/Leaves
            _buildStatContainer(
              icon: Icons.eco,
              value: state is StartGameLoaded ? (state.experience ~/ 100).toString() : '0',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatContainer({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Game Island/Map with Action Buttons
        Expanded(
          child: Stack(
            children: [
              _buildGameIsland(),
              // PlantGo Title with animation
              _buildSafeAnimationWrapper(() => const GameTitleAnimation(
                title: 'PlantGo',
                imageWidth: 280,
                imageHeight: 140,
                top: 60,
                padding: EdgeInsets.symmetric(horizontal: 20),
              )),
              // Action Buttons positioned at bottom right
              Positioned(
                bottom: 80,
                right: 24,
                child: Column(
                  children: [
                    // Start Game Button
                    _buildActionButton(
                      text: 'Start game',
                      onPressed: () {
                        context.read<StartGameCubit>().startGame();
                        Navigator.pushReplacementNamed(context, AppRoutes.main);
                      },
                      isPrimary: true,
                    ),
                    const SizedBox(height: 12),
                    // Leaderboard Button
                    _buildActionButton(
                      text: 'Leaderboard',
                      onPressed: () {
                        // Navigate to leaderboard screen
                        Navigator.pushNamed(context, AppRoutes.leaderboard);
                      },
                      isPrimary: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContentWithoutTitle() {
    return BlocBuilder<StartGameCubit, StartGameState>(
      builder: (context, state) {
        return Column(
          children: [
            // Main content area without title or header
            Expanded(
              child: Column(
                children: [
                  // Game Island/Map with Action Buttons
                  Expanded(
                    child: Stack(
                      children: [
                        _buildGameIsland(),
                        // Action Buttons positioned at bottom right
                        Positioned(
                          bottom: 80,
                          right: 24,
                          child: Column(
                            children: [
                              // Start Game Button
                              _buildActionButton(
                                text: 'Start game',
                                onPressed: () {
                                  context.read<StartGameCubit>().startGame();
                                  Navigator.pushReplacementNamed(context, AppRoutes.main);
                                },
                                isPrimary: true,
                              ),
                              const SizedBox(height: 12),
                              // Leaderboard Button
                              _buildActionButton(
                                text: 'Leaderboard',
                                onPressed: () {
                                  // Navigate to leaderboard screen
                                  Navigator.pushNamed(context, AppRoutes.leaderboard);
                                },
                                isPrimary: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGameIsland() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // Island/Map background
          // Center(
          //   child: Container(
          //     width: double.infinity,
          //     height: 300,
          //     decoration: BoxDecoration(
          //       gradient: RadialGradient(
          //         center: Alignment.center,
          //         radius: 0.8,
          //         colors: [
          //           AppColors.primary.withOpacity(0.3),
          //           AppColors.background.withOpacity(0.1),
          //         ],
          //       ),
          //       borderRadius: BorderRadius.circular(150),
          //     ),
          //     child: Stack(
          //       children: [
          //         // Paths
          //         Positioned(
          //           top: 100,
          //           left: 50,
          //           right: 50,
          //           child: Container(
          //             height: 3,
          //             decoration: BoxDecoration(
          //               color: Colors.brown.withOpacity(0.3),
          //               borderRadius: BorderRadius.circular(2),
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // Character with animation
          _buildSafeAnimationWrapper(() => const MascotAnimation(
            width: 180,
            height: 300,
            bottom: 30,
            left: 4,
          )),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: 180,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primary : Colors.transparent,
          foregroundColor: isPrimary ? Colors.black : AppColors.primary,
          side: isPrimary ? null : BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: isPrimary ? 8 : 0,
          shadowColor: isPrimary ? AppColors.primary.withOpacity(0.3) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.asset(
            //   AppImages.mascots,
            //   width: 20,
            //   height: 20,
            //   fit: BoxFit.cover,
            // ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomAppBar(
      // notch removed
      color: AppColors.bottomNavBackground,
      child: Container(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
              0,
              'assets/icons/home.png',
              'assets/icons/home_active.png',
              'Home',
            ),
            _buildNavItem(
              1,
              'assets/icons/explore.png',
              'assets/icons/expl_active.png',
              'Explore',
            ),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(
              2,
              'assets/icons/noti.png',
              'assets/icons/noti_active.png',
              'Notifications',
            ),
            _buildNavItem(
              3,
              'assets/icons/profile.png',
              'assets/icons/profile_active.png',
              'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String iconPath,
    String activeIconPath,
    String label,
  ) {
    final bool isActive = _selectedIndex == index;
    return IconButton(
      icon: Image.asset(
        isActive ? activeIconPath : iconPath,
        width: 24,
        height: 24,
        color: isActive ? AppColors.iconActive : AppColors.iconDefault,
      ),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}
