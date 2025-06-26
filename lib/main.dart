import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:plantgo/app.dart';
import 'package:plantgo/core/dependency_injection.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize dependency injection
  await configureDependencies();
  
  runApp(const PlantGoApp());
}
