import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loader
class EnvConfig {
  EnvConfig._();

  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  /// PlantID API Key for plant identification
  static String get plantIdApiKey => dotenv.env['PLANT_ID_API_KEY'] ?? '';

  /// App environment (development/staging/production)
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  /// Debug mode flag
  static bool get isDebug => dotenv.env['DEBUG_MODE'] == 'true';

  /// Check if PlantID API is configured
  static bool get hasPlantIdKey =>
      plantIdApiKey.isNotEmpty && plantIdApiKey != 'your_plant_id_api_key_here';
}
