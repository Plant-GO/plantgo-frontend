/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'PlantGo';
  static const String appVersion = '1.0.0';

  // PlantID API
  static const String plantIdBaseUrl = 'https://api.plant.id/v3';
  static const String plantIdIdentifyEndpoint = '/identification';

  // Custom Model Backend (Backend_CV)
  static const String customModelBaseUrl = 'http://10.0.2.2:8000'; // localhost for Android emulator
  static const String customModelEndpoint = '/predict-plant-base64';

  // Map Configuration (OSM)
  static const double defaultMapZoom = 15.0;
  static const double maxMapZoom = 18.0;
  static const double minMapZoom = 3.0;

  // Default location (Portland, OR - as shown in mockup)
  static const double defaultLatitude = 45.5155;
  static const double defaultLongitude = -122.6789;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Level Configuration
  static const int maxLevels = 5;
  static const int maxStars = 3;

  // XP & Rewards
  static const int xpPerCommonPlant = 50;
  static const int xpPerUncommonPlant = 100;
  static const int xpPerRarePlant = 150;
  static const int xpPerEpicPlant = 200;
  static const int xpPerLegendaryPlant = 250;

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String plantDiscoveriesCollection = 'plant_discoveries';
  static const String levelsCollection = 'levels';
}
