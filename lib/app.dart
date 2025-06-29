import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/configs/app_colors.dart';
import 'package:plantgo/configs/app_routes.dart';
import 'package:plantgo/core/dependency_injection.dart';
import 'package:plantgo/presentation/blocs/auth/auth_cubit.dart';
import 'package:plantgo/presentation/blocs/course/course_cubit.dart';
import 'package:plantgo/presentation/blocs/map/map_cubit.dart';
import 'package:plantgo/presentation/blocs/notifications/notifications_cubit.dart';
import 'package:plantgo/presentation/blocs/profile/profile_cubit.dart';
import 'package:plantgo/presentation/blocs/start_game/start_game_cubit.dart';
import 'package:plantgo/core/services/audio_service.dart';

class PlantGoApp extends StatefulWidget {
  const PlantGoApp({super.key});

  @override
  State<PlantGoApp> createState() => _PlantGoAppState();
}

class _PlantGoAppState extends State<PlantGoApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Stop background audio when app is disposed
    AudioService.instance.stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => getIt<AuthCubit>(),
        ),
        BlocProvider<CourseCubit>(
          create: (_) => getIt<CourseCubit>(),
        ),
        BlocProvider<StartGameCubit>(
          create: (_) => getIt<StartGameCubit>(),
        ),
        BlocProvider<MapCubit>(
          create: (_) => getIt<MapCubit>(),
        ),
        BlocProvider<NotificationsCubit>(
          create: (_) => getIt<NotificationsCubit>(),
        ),
        BlocProvider<ProfileCubit>(
          create: (_) => getIt<ProfileCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'PlantGo',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        onGenerateRoute: AppRoutes.generateRoute,
        initialRoute: AppRoutes.splash,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        brightness: Brightness.light, // Changed to light for better auth screen contrast
        surface: Colors.white,
        background: Colors.white,
        onSurface: AppColors.textDark,
        onBackground: AppColors.textDark,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBlue2,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textLight),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
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
        bodyLarge: TextStyle(fontFamily: 'Nunito', color: AppColors.textDark),
        bodyMedium: TextStyle(fontFamily: 'Nunito', color: AppColors.textDark),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        labelStyle: TextStyle(color: AppColors.textDark, fontFamily: 'Nunito'),
        hintStyle: TextStyle(color: AppColors.wolf, fontFamily: 'Nunito'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        errorStyle: TextStyle(color: AppColors.error, fontFamily: 'Nunito'),
      ),
      // Use custom themes for dark screens like home/profile, but default to light for auth
      brightness: Brightness.light,
    );
  }
}
