import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Firebase imports - uncomment when firebase is configured
// import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/env/env_config.dart';
import 'providers/course_provider.dart';
import 'providers/map_provider.dart';
import 'providers/user_provider.dart';
import 'providers/scan_provider.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase - uncomment when firebase is configured
  // await Firebase.initializeApp();

  runApp(const PlantGoApp());
}

class PlantGoApp extends StatelessWidget {
  const PlantGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
      ],
      child: MaterialApp(
        title: 'PlantGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigation(),
      ),
    );
  }
}
