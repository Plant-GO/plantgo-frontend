# plantgo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# PlantGo - Plant Identification & Riddle Game

A Flutter application featuring plant identification using camera scanning and interactive plant riddles.

## Features

### 🌱 Plant Scanner
- Real-time camera-based plant identification
- Advanced scanning animations and effects
- Integration with plant identification APIs

### 🧩 Plant Riddles
- Interactive riddle game with plant identification challenges
- Beautiful UI with custom background design
- Backend API integration for dynamic riddle content
- Progressive difficulty levels

### 🎨 Design
- Modern, nature-themed UI
- Custom animations and transitions
- Responsive design for various screen sizes

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd plantgo-frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Architecture

The app follows Clean Architecture principles with:
- **Data Layer**: API services, models, repositories
- **Domain Layer**: Entities, use cases, repository interfaces  
- **Presentation Layer**: BLoC/Cubit state management, UI screens

## Riddle Feature

The riddle feature has been fully implemented with:
- ✅ Backend API integration (`http://localhost:8080`)
- ✅ Custom UI matching design specifications
- ✅ Proper state management with BLoC pattern
- ✅ Error handling and loading states
- ✅ Integration with plant scanner

### API Endpoints
- `GET /riddles/level/{levelIndex}` - Get riddle by level
- `GET /riddles/active` - Get active riddles
- `GET /riddles` - Get all riddles

### UI Layout
The riddle screen features positioned elements matching the background design:
- **Scientific Name**: Top cream-colored area
- **Riddle Part**: Middle cream-colored area with riddle text
- **Scanner Button**: Bottom section to launch plant scanner

For detailed implementation information, see [RIDDLE_IMPLEMENTATION.md](RIDDLE_IMPLEMENTATION.md).

---
