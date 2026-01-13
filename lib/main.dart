import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'providers/course_provider.dart';
import 'providers/map_provider.dart';
import 'providers/user_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/nft_provider.dart';
import 'providers/verification_provider.dart';
import 'services/backend_url_provider.dart';
import 'screens/main_navigation.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Preload backend URL (caches it for faster first request)
  await BackendUrlProvider.getBackendUrl();

  // Check if user has completed onboarding
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding =
      prefs.getBool('hasCompletedOnboarding') ?? false;
  final userName = prefs.getString('userName');
  final userId = prefs.getString('userId') ?? prefs.getString('deviceId');
  final userEmail = prefs.getString('userEmail');
  final isGuest = prefs.getBool('isGuest') ?? true;

  runApp(PlantGoApp(
    hasCompletedOnboarding: hasCompletedOnboarding,
    userName: userName,
    userId: userId,
    userEmail: userEmail,
    isGuest: isGuest,
  ));
}

class PlantGoApp extends StatelessWidget {
  final bool hasCompletedOnboarding;
  final String? userName;
  final String? userId;
  final String? userEmail;
  final bool isGuest;

  const PlantGoApp({
    super.key,
    required this.hasCompletedOnboarding,
    this.userName,
    this.userId,
    this.userEmail,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()
          ..setUserName(userName ?? '')
          ..setDeviceId(userId ?? '')
          ..setEmail(userEmail)
          ..setIsGuest(isGuest)),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        // Blockchain providers
        ChangeNotifierProvider(create: (_) => WalletProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => NFTProvider()),
        // Verification provider
        ChangeNotifierProvider(create: (_) => VerificationProvider()),
      ],
      child: MaterialApp(
        title: 'PlantGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: hasCompletedOnboarding 
            ? const MainNavigation() 
            : const LoginScreen(),
      ),
    );
  }
}
