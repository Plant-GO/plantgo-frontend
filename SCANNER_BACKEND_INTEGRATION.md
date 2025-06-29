# Plant Scanner Backend Integration

This document explains how the PlantGo Flutter frontend connects to the Go backend for plant scanning functionality.

## Overview

The plant scanner uses two methods to communicate with the Go backend:

1. **Single Image Scanning** - HTTP POST to `/scan/image`
2. **Live Video Streaming** - WebSocket connection to `/scan/video`

## Architecture

```
Flutter Frontend          Go Backend
├── PlantScannerScreen    ├── /scan/image (HTTP POST)
├── ScannerCubit          └── /scan/video (WebSocket)
├── PlantScannerService
└── ApiService
```

## Backend Endpoints

### 1. Single Image Scanning

**Endpoint:** `POST /scan/image`
- **Method:** HTTP POST with multipart form data
- **Input:** Image file
- **Output:** JSON response with plant prediction

**Request Format:**
```
Content-Type: multipart/form-data
Body: image file
```

**Response Format:**
```json
{
  "prediction": "Rose",
  "confidence": 0.85
}
```

### 2. Live Video Streaming

**Endpoint:** `GET /scan/video`
- **Method:** WebSocket connection
- **Input:** Base64 encoded video frames
- **Output:** Real-time plant predictions

**Request Format (Client → Server):**
```json
{
  "type": "frame",
  "data": {
    "image": "base64_encoded_image_data...",
    "timestamp": 1640995200000
  }
}
```

**Response Format (Server → Client):**
```json
{
  "type": "prediction",
  "data": {
    "prediction": "Rose",
    "confidence": 0.85
  }
}
```

## Frontend Implementation

### Components

1. **PlantScannerScreen** - UI component with camera preview and animations
2. **ScannerCubit** - State management for scanner operations
3. **PlantScannerService** - Service layer for backend communication
4. **ApiService** - HTTP client for single image scanning

### Key Files

- `lib/presentation/screens/scanner/plant_scanner_screen.dart` - Main scanner UI
- `lib/presentation/blocs/scanner/scanner_cubit.dart` - State management
- `lib/services/plant_scanner_service.dart` - Backend communication service
- `lib/api/api_service.dart` - HTTP API client

### State Management

The scanner uses BLoC pattern with the following states:

- `ScannerInitial` - Initial state
- `ScannerInitializing` - Setting up camera and connection
- `ScannerReady` - Ready to scan
- `ScannerScanning` - Currently scanning with confidence level
- `ScannerSuccess` - Plant identified successfully
- `ScannerError` - Error occurred during scanning

## Configuration

### Backend URL Configuration

Update the backend URL in `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  static const String baseUrl = 'http://localhost:8080'; // Go backend HTTP
  static const String webSocketUrl = 'ws://localhost:8080'; // Go backend WebSocket
  static const String scanImageEndpoint = '/scan/image';
  static const String scanVideoEndpoint = '/scan/video';
}
```

### Dependency Injection

The scanner service is registered in `lib/core/dependency_injection.dart`:

```dart
getIt.registerLazySingleton<PlantScannerService>(() => PlantScannerService(getIt<ApiService>()));
getIt.registerFactory<ScannerCubit>(() => ScannerCubit(getIt<PlantScannerService>()));
```

## Usage Flow

### Single Image Scanning

1. User takes photo using camera
2. Image is sent to Go backend via HTTP POST
3. Backend processes image and returns prediction
4. Result is displayed to user

### Live Video Streaming

1. Scanner initializes WebSocket connection to Go backend
2. Camera captures frames at 2 FPS
3. Each frame is base64 encoded and sent via WebSocket
4. Go backend processes frames in real-time
5. Predictions are streamed back to frontend
6. UI updates with confidence levels and final result

## Error Handling

- **Connection Errors:** Automatic fallback to single image scanning
- **Camera Errors:** User-friendly error messages with retry options
- **Backend Errors:** Graceful degradation with informative messages

## Testing

### Local Development

1. Start Go backend server on `localhost:8080`
2. Ensure WebSocket endpoint `/scan/video` is available
3. Ensure HTTP endpoint `/scan/image` accepts multipart form data
4. Run Flutter app with `flutter run`

### Production

Update `app_constants.dart` with production backend URLs:

```dart
static const String baseUrl = 'https://api.plantgo.com';
static const String webSocketUrl = 'wss://api.plantgo.com';
```

## Performance Considerations

- **Frame Rate:** Limited to 2 FPS to reduce bandwidth usage
- **Image Quality:** Images are compressed before transmission
- **Connection Management:** Automatic reconnection on WebSocket failure
- **Memory Management:** Proper disposal of camera and WebSocket resources

## Security

- **Authentication:** JWT tokens can be added to WebSocket headers
- **Rate Limiting:** Backend should implement rate limiting for scanning endpoints
- **Input Validation:** Images are validated before transmission

## Troubleshooting

### Common Issues

1. **WebSocket Connection Failed**
   - Check backend server is running
   - Verify WebSocket endpoint is accessible
   - Check network connectivity

2. **Camera Initialization Failed**
   - Verify camera permissions are granted
   - Check device has camera capability
   - Restart the app

3. **Scanning Timeout**
   - Check backend processing time
   - Verify image quality and size
   - Check network stability

### Debug Logs

Enable debug logging in the scanner service:

```dart
// In PlantScannerService
print('WebSocket connection status: ${_isConnected}');
print('Sending frame: ${base64Image.length} bytes');
```
