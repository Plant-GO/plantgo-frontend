# PlantGo

Plant identification and gamified learning mobile application built with Flutter.

## Quick Start

### Prerequisites
- Flutter SDK 3.7.0+
- Android Studio or Xcode
- Firebase account

### Installation

```bash
git clone <repository-url>
cd plantgo-frontend
flutter pub get
```

Configure Firebase by adding `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to their respective directories.

```bash
flutter run
```

## Features

### Plant Scanner
Real-time plant identification using camera with WebSocket streaming to Go backend. Supports both live video streaming and single image scanning.

**Backend Endpoints:**
- WebSocket: `ws://localhost:8080/scan/video`
- HTTP: `POST http://localhost:8080/scan/image`

**Protocol:**
```json
// Client -> Server
{
  "type": "frame",
  "data": {
    "image": "base64_encoded_image",
    "timestamp": 1640995200000
  }
}

// Server -> Client
{
  "type": "prediction",
  "data": {
    "prediction": "Rose",
    "confidence": 0.85
  }
}
```

### Plant Riddles
Progressive plant-themed challenges with backend integration. Fallback to mock data when backend unavailable.

**Endpoints:**
- `GET /riddles/level/{levelIndex}` - Riddle by level
- `GET /riddles/active` - Active riddles
- `GET /riddles` - All riddles

### Interactive Map
Geolocation-based plant discovery using Flutter Map and Firebase Firestore. Add plants with photos and GPS coordinates.

### User Authentication
Firebase Authentication with email/password, Google Sign-In, and guest mode support.

### Progress Tracking
Streak tracking, achievements, course completion, and profile management with Firebase Firestore persistence.

## Architecture

Clean Architecture with three layers:

```
Presentation (UI + BLoC)
    ↓
Domain (Use Cases + Entities)
    ↓
Data (Repositories + API)
```

**State Management:** flutter_bloc  
**Dependency Injection:** GetIt + Injectable  
**Networking:** Dio + Retrofit  
**Database:** Firebase (Auth, Firestore)

## Project Structure

```
lib/
├── api/              REST API services
├── core/             Dependency injection, services
├── data/             Models, repository implementations
├── domain/           Entities, use cases, repository interfaces
├── presentation/     Screens, blocs, widgets
├── services/         App-specific services
└── configs/          App configuration
```

## Configuration

### Backend URL
Configure in `lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'http://your-ip:8080';
```

Can be changed at runtime via Settings screen.

### Firebase
Config files required:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## Development

### Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Analysis
```bash
flutter analyze
flutter format .
```

### Testing
```bash
flutter test
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| flutter_bloc ^8.1.6 | State management |
| dio ^5.7.0 | HTTP client |
| retrofit ^4.4.1 | Type-safe API |
| firebase_core ^2.24.2 | Firebase integration |
| camera ^0.10.5+5 | Camera access |
| flutter_map ^6.1.0 | Map display |
| get_it ^7.7.0 | Dependency injection |

See [pubspec.yaml](pubspec.yaml) for complete list.

## Known Issues

- Some cubits use mock data pending full backend integration
- Info-level analyzer warnings (avoid_print, deprecated_member_use) present but non-critical

## Recent Changes

### v1.0.0 (2026-01-01)
- Fixed dependency conflict (retrofit_generator -> v9.2.0)
- Removed duplicate service files
- Fixed linting warnings
- Consolidated documentation

## License

Proprietary - All rights reserved
