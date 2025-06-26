import 'package:flutter/material.dart';
import 'package:plantgo/presentation/screens/splash/splash_screen.dart';
import 'package:plantgo/presentation/screens/auth/auth_welcome_screen.dart';
import 'package:plantgo/presentation/screens/auth/login_screen.dart';
import 'package:plantgo/presentation/screens/auth/register_screen.dart';
import 'package:plantgo/presentation/screens/start_game/start_game_screen.dart';
import 'package:plantgo/presentation/screens/main/main_screen.dart';
import 'package:plantgo/presentation/screens/course/course_screen.dart';
import 'package:plantgo/presentation/screens/plant_riddle/plant_riddle_screen.dart';
import 'package:plantgo/presentation/screens/map/map_screen.dart';
import 'package:plantgo/presentation/screens/profile/profile_screen.dart';
import 'package:plantgo/presentation/screens/streak/streak_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String authWelcome = '/auth-welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String startGame = '/start-game';
  static const String main = '/main';
  static const String course = '/course';
  static const String riddle = '/riddle';
  static const String map = '/map';
  static const String profile = '/profile';
  static const String streak = '/streak';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      
      case authWelcome:
        return MaterialPageRoute(
          builder: (_) => const AuthWelcomeScreen(),
          settings: settings,
        );
      
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      
      case startGame:
        return MaterialPageRoute(
          builder: (_) => const StartGameScreen(),
          settings: settings,
        );
      
      case main:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );
      
      case course:
        return MaterialPageRoute(
          builder: (_) => const CourseScreen(),
          settings: settings,
        );
      
      case riddle:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PlantRiddleScreen(
            levelIndex: args?['levelIndex'] ?? 0,
          ),
          settings: settings,
        );
      
      case map:
        return MaterialPageRoute(
          builder: (_) => const MapScreen(),
          settings: settings,
        );
      
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      
      case streak:
        return MaterialPageRoute(
          builder: (_) => const StreakScreen(),
          settings: settings,
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
