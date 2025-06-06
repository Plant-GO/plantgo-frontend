import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'utils/app_colors.dart'; // Import AppColors
import 'screens/osm_map.dart';

// Placeholder for a potential "Add/Center Action" screen or modal
class CenterActionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Center Action')),
      body: Center(child: Text('This is the Center Action Screen', style: TextStyle(color: AppColors.textLight))),
      backgroundColor: AppColors.background,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantGo',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent, // Accent color
          brightness: Brightness.dark,
          background: AppColors.background,
          surface: AppColors.darkBlue1, // For cards, dialogs etc.
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBlue2, // Darker app bars
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textLight),
          titleTextStyle: TextStyle(fontFamily: 'Poppins', color: AppColors.textLight, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.bottomNavBackground,
          selectedItemColor: AppColors.iconActive,
          unselectedItemColor: AppColors.iconDefault,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Nunito', color: AppColors.textLight),
          bodyMedium: TextStyle(fontFamily: 'Nunito', color: AppColors.textLight),
          headlineSmall: TextStyle(fontFamily: 'Poppins', color: AppColors.textLight, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontFamily: 'Poppins', color: AppColors.textLight, fontWeight: FontWeight.bold),
        ),
        brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
      home: MainAppShell(),
    );
  }
}

class MainAppShell extends StatefulWidget {
  @override
  _MainAppShellState createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0; // Default to Home screen

  // Screens for the BottomNavigationBar items (excluding the FAB)
  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    // Placeholder for FAB action, actual navigation to a screen for FAB is handled separately
    NotificationsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions, 
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action for the central button
          // This could navigate to a new screen, show a modal, etc.
          Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen()));
        },
        child: Image.asset('assets/icons/map.png', width: 40, height: 48,), // Using snow for icon color on FAB
        backgroundColor: AppColors.primary, // FeatherGreen
        elevation: 4.0,
        shape: CircleBorder(), // Ensure the FAB is circular
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: AppColors.bottomNavBackground,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(0, 'assets/icons/home.png', 'assets/icons/home_active.png', 'Home'),
              _buildNavItem(1, 'assets/icons/explore.png', 'assets/icons/expl_active.png', 'Explore'),
              SizedBox(width: 40), // The space for the FAB
              _buildNavItem(2, 'assets/icons/noti.png', 'assets/icons/noti_active.png', 'Notifications'),
              _buildNavItem(3, 'assets/icons/profile.png', 'assets/icons/profile_active.png', 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String activeIconPath, String label) {
    bool isActive = _selectedIndex == index;
    return IconButton(
      icon: Image.asset(
        isActive ? activeIconPath : iconPath, 
        width: 24, 
        height: 24, 
        color: isActive ? AppColors.iconActive : AppColors.iconDefault
      ),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}
