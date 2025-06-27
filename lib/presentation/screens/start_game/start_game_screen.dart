import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/configs/app_colors.dart';
import 'package:plantgo/configs/app_routes.dart';
import 'package:plantgo/core/constants/app_images.dart';
import 'package:plantgo/presentation/blocs/start_game/start_game_cubit.dart';
import 'package:plantgo/presentation/blocs/start_game/start_game_state.dart';
import 'package:plantgo/presentation/screens/explore/explore_screen.dart';
import 'package:plantgo/presentation/screens/map/map_screen.dart';
import 'package:plantgo/presentation/screens/notifications/notifications_screen.dart';
import 'package:plantgo/presentation/screens/profile/profile_screen.dart';
import 'package:plantgo/presentation/blocs/map/map_cubit.dart';
import 'package:plantgo/presentation/blocs/profile/profile_cubit.dart';

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({Key? key}) : super(key: key);

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}

class _StartGameScreenState extends State<StartGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _cloudAnimationController;
  late AnimationController _characterAnimationController;
  late AnimationController _starAnimationController;
  late Animation<Offset> _cloudAnimation1;
  late Animation<Offset> _cloudAnimation2;
  late Animation<double> _characterBounce;
  late List<Animation<double>> _starTwinkleAnimations;
  
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
    _initializeAnimations();
    context.read<StartGameCubit>().loadStartGameData();
    
    // Initialize BLoCs
    context.read<ProfileCubit>().loadProfile();
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

  void _initializeAnimations() {
    // Cloud floating animation
    _cloudAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _cloudAnimation1 = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: const Offset(0.1, 0),
    ).animate(CurvedAnimation(
      parent: _cloudAnimationController,
      curve: Curves.easeInOut,
    ));

    _cloudAnimation2 = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: const Offset(-0.1, 0),
    ).animate(CurvedAnimation(
      parent: _cloudAnimationController,
      curve: Curves.easeInOut,
    ));

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

    // Star twinkling animation
    _starAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Create different twinkling animations for each star with different delays
    _starTwinkleAnimations = List.generate(8, (index) {
      return Tween<double>(
        begin: 0.1,
        end: 0.8,
      ).animate(CurvedAnimation(
        parent: _starAnimationController,
        curve: Interval(
          (index * 0.125), // Stagger the start times
          1.0,
          curve: Curves.easeInOut,
        ),
      ));
    });

    // Start animations
    _cloudAnimationController.repeat(reverse: true);
    _characterAnimationController.repeat(reverse: true);
    _starAnimationController.repeat(reverse: true);
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
  void dispose() {
    _cloudAnimationController.dispose();
    _characterAnimationController.dispose();
    _starAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _selectedIndex == 0 
        ? Stack(
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1a3a2e),
                      Color(0xFF16302c),
                      Color(0xFF0f241f),
                    ],
                  ),
                ),
              ),
              // Background stars/sparkles
              _buildBackgroundElements(),
              // Main content
              _buildStartGameContent(),
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

  Widget _buildBackgroundElements() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _cloudAnimationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Floating clouds
              Positioned(
                top: 100,
                left: 30,
                child: SlideTransition(
                  position: _cloudAnimation1,
                  child: Image.asset(
                    AppImages.clouds,
                    width: 100,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 180,
                right: 80,
                child: SlideTransition(
                  position: _cloudAnimation2,
                  child: Image.asset(
                    AppImages.clouds,
                    width: 60,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Sparkles/stars
              ...List.generate(
                8,
                (index) => Positioned(
                  top: 80 + (index * 50.0),
                  left: 30 + (index % 3) * 120.0,
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(StartGameState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
        // PlantGo Title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.maskGreen,
                AppColors.bee,
              ],
            ).createShader(bounds),
            child: const Text(
              'PlantGo',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
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
    );
  }

  Widget _buildGameIsland() {
    return AnimatedBuilder(
      animation: _characterAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              // Island/Map background
              Center(
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.background.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(150),
                  ),
                  child: Stack(
                    children: [
                      // Trees/Foliage
                      ...List.generate(
                        6,
                        (index) => Positioned(
                          top: 50 + (index % 3) * 80.0,
                          left: 30 + (index % 2) * 200.0,
                          child: Icon(
                            Icons.park,
                            color: AppColors.primary.withOpacity(0.6),
                            size: 40 + (index % 3) * 10,
                          ),
                        ),
                      ),
                      // Paths
                      Positioned(
                        top: 100,
                        left: 50,
                        right: 50,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.brown.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Character
              Positioned(
                bottom: 30,
                left: 4,
                child: Transform.translate(
                  offset: Offset(0, _characterBounce.value),
                  child: Image.asset(
                    AppImages.mascots,
                    width: 180, // Reduced width to avoid overlap with buttons
                    height: 300, // Proportionally reduced height
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
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
