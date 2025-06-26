import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/configs/app_colors.dart';
import 'package:plantgo/presentation/screens/course/course_screen.dart';
import 'package:plantgo/presentation/screens/explore/explore_screen.dart';
import 'package:plantgo/presentation/screens/map/map_screen.dart';
import 'package:plantgo/presentation/screens/notifications/notifications_screen.dart';
import 'package:plantgo/presentation/screens/profile/profile_screen.dart';
import 'package:plantgo/presentation/blocs/course/course_cubit.dart';
import 'package:plantgo/presentation/blocs/map/map_cubit.dart';
import 'package:plantgo/presentation/blocs/profile/profile_cubit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const CourseScreen(),
      const ExploreScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
    
    // Initialize BLoCs
    context.read<CourseCubit>().loadCourse();
    context.read<ProfileCubit>().loadProfile();
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
      body: IndexedStack(
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
      bottomNavigationBar: BottomAppBar(
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
