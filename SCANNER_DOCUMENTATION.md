# PlantGo Scanner - Go Backend Integration

## ✅ COMPATIBILITY UPDATE
**Important**: The scanner has been updated to work with **Go WebSocket backends**. Socket.io is no longer used.

## Overview
The PlantGo scanner provides real-time plant identification through camera streaming and native WebSocket communication with Go backends.

## Features

### 🎨 Enhanced Animations
- **Smooth scanning line** with gradient effects and glow
- **Breathing corner indicators** with opacity and size animations
- **Particle effects** floating around the scan area
- **Ripple waves** with multiple expanding circles
- **Pulsing scan area** with subtle scale animations
- **Staggered animation timing** for natural flow

### 📱 Real-time Scanning
- **Video frame streaming** at 2 FPS to backend
- **Native WebSocket integration** (works with Go backends)
- **Progress indicators** showing analysis confidence
- **Live feedback** during scanning process

### 🔧 Technical Features
- **Camera permission handling**
- **Error recovery** and user feedback
- **Optimized frame processing** with JPEG compression
- **Session management** for tracking scans
- **Go backend compatibility** with native WebSocket protocol

## Usage

### 1. Basic Integration
The scanner is already integrated into your map screen. Users can access it by tapping the "Smart Plant Scanner" option in the plant capture bottom sheet.

### 2. Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PlantScannerScreen(),
  ),
).then((result) {
  if (result != null) {
    _handleScannedPlant(result);
  }
});
```

### 3. Handling Results
```dart
void _handleScannedPlant(Map<String, dynamic> scanResult) {
  final plantName = scanResult['plantName'] as String;
  final confidence = scanResult['confidence'] as double;
  
  // Add plant to map or show details
  print('Plant identified: $plantName (${(confidence * 100).toInt()}% confidence)');
}
```

## Go Backend Integration

### 1. WebSocket Connection
```
ws://localhost:8080/ws
```

### 2. Message Protocol

#### Client → Server (Flutter to Go)
```json
{
  "type": "video_frame",
  "sessionId": "scanner_session_unique_id", 
  "frame": "base64_image_data",
  "timestamp": 1640995200000
}
```

#### Server → Client (Go to Flutter)
```json
// Plant identification result
{
  "type": "plant_identified",
  "plantName": "Monstera Deliciosa",
  "confidence": 0.92,
  "sessionId": "scanner_session_unique_id"
}

// Scanning progress update
{
  "type": "scanning_progress",
  "confidence": 0.65,
  "sessionId": "scanner_session_unique_id"
}
```

### 3. Go Backend Setup
Start your Go backend:
```bash
cd go_backend_example
go run main.go
```

Server runs on `http://localhost:8080` with WebSocket endpoint at `/ws`.

### 2. REST API Endpoints

#### Start Scanning Session
```http
POST /api/v1/plants/scan/start
Content-Type: application/json

{
  "sessionId": "scanner_session_unique_id"
}
```

#### Send Frame for Analysis
```http
POST /api/v1/plants/analyze/realtime
Content-Type: application/json

{
  "frame": "base64_image_data",
  "sessionId": "scanner_session_unique_id",
  "location": {
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "timestamp": 1640995200000
}
```

#### Stop Scanning Session
```http
POST /api/v1/plants/scan/stop
Content-Type: application/json

{
  "sessionId": "scanner_session_unique_id"
}
```

## Animation Details

### 1. Scanning Line
- **Duration**: 2.5 seconds with reverse
- **Curve**: `Curves.easeInOutCubic`
- **Effect**: Gradient with multiple color stops and glow shadow

### 2. Corner Indicators
- **Duration**: 4 seconds breathing cycle
- **Effect**: Size scaling from 85% to 100% with opacity changes
- **Glow**: Box shadow with accent color

### 3. Pulse Animation
- **Duration**: 2.2 seconds with reverse
- **Scale**: 1.0 to 1.08
- **Curve**: `Curves.easeInOutSine`

### 4. Particle System
- **Count**: 25 particles
- **Movement**: Sine wave oscillation with random phases
- **Colors**: Mix of primary, accent, and white particles
- **Opacity**: Distance-based fading from center

### 5. Ripple Effects
- **Waves**: 4 concurrent ripples with phase offset
- **Elements**: Circles with orbital dots
- **Opacity**: Fade out as waves expand

## Performance Optimizations

### 1. Frame Rate Control
- Limited to 2 FPS for video streaming
- Optimized camera resolution (ResolutionPreset.high)
- JPEG compression for smaller payload

### 2. Animation Efficiency
- Use of `AnimatedBuilder` for selective rebuilds
- Staggered animation starts to reduce CPU spikes
- Custom painters for complex effects

### 3. Memory Management
- Proper disposal of animation controllers
- Camera controller cleanup
- Socket connection management

## Configuration

### 1. Backend URL
Update the WebSocket URL in the scanner:
```dart
_socket = IO.io('ws://your-backend-url:3000', <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false,
});
```

### 2. Animation Timing
Adjust animation durations in `_initializeAnimations()`:
- Scanning line speed
- Breathing rhythm
- Particle movement speed
- Ripple wave frequency

### 3. Visual Style
Customize colors and effects:
- Change `AppColors.primary` and `AppColors.accent`
- Adjust shadow blur radius and spread
- Modify particle count and behavior

## Testing

### 1. Without Backend
The scanner will work without a backend connection, showing animations and UI. Mock the socket events for testing:

```dart
// Simulate plant identification after 3 seconds
Future.delayed(const Duration(seconds: 3), () {
  setState(() {
    _scanResult = 'Monstera Deliciosa';
    _confidence = 0.95;
    _isScanning = false;
    _isStreaming = false;
  });
});
```

### 2. With Mock Backend
Create a simple Node.js server with Socket.io for testing real-time communication.

## Troubleshooting

### 1. Camera Issues
- Check permissions in iOS `Info.plist` and Android `AndroidManifest.xml`
- Handle camera initialization errors gracefully
- Provide fallback for devices without camera

### 2. Animation Performance
- Reduce particle count on lower-end devices
- Adjust animation durations for smoother performance
- Use `RepaintBoundary` for expensive widgets

### 3. Network Issues
- Implement retry logic for socket connections
- Handle offline scenarios gracefully
- Provide user feedback for network errors

## Future Enhancements

1. **AR Features**: Overlay plant information on camera view
2. **Offline Mode**: Local plant identification with TensorFlow Lite
3. **Multi-plant Detection**: Identify multiple plants in single frame
4. **Historical Scans**: Save scan history with timestamps
5. **Sound Effects**: Audio feedback for successful identification
6. **Haptic Feedback**: Vibration patterns for different scan states
