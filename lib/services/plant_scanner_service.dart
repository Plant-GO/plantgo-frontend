import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/core/constants/app_constants.dart';

@injectable
class PlantScannerService {
  final ApiService _apiService;
  
  WebSocketChannel? _channel;
  bool _isConnected = false;
  
  PlantScannerService(this._apiService);
  
  /// Initialize WebSocket connection for live video streaming to Go backend
  Future<WebSocketChannel?> initializeWebSocket() async {
    try {
      // Close existing connection if any
      closeConnection();
      
      final wsUrl = '${AppConstants.webSocketUrl}${AppConstants.scanVideoEndpoint}';
      print('PlantScannerService: Attempting to connect to WebSocket: $wsUrl');
      
      // Add timeout to prevent hanging
      _channel = IOWebSocketChannel.connect(
        wsUrl,
        connectTimeout: const Duration(seconds: 5),
      );
      
      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Test connection by sending a ping
      try {
        _channel!.sink.add(jsonEncode({
          'type': 'ping',
          'data': {'timestamp': DateTime.now().millisecondsSinceEpoch}
        }));
        
        _isConnected = true;
        print('PlantScannerService: WebSocket connected successfully to Go backend');
        return _channel;
      } catch (e) {
        print('PlantScannerService: Failed to send ping: $e');
        _isConnected = false;
        _channel = null;
        return null;
      }
    } catch (e) {
      print('PlantScannerService: Failed to connect to WebSocket: $e');
      print('PlantScannerService: This is normal if the Go backend server is not running');
      print('PlantScannerService: The app will fallback to single image scanning mode');
      _isConnected = false;
      _channel = null;
      return null;
    }
  }
  
  /// Send frame to Go backend for real-time analysis
  /// Expected format: {"type": "frame", "data": {"image": "base64...", "timestamp": 123}}
  void sendFrame(String base64Image) {
    if (!_isConnected || _channel == null) {
      print('PlantScannerService: Cannot send frame - WebSocket not connected');
      throw Exception('WebSocket not connected');
    }
    
    try {
      print('PlantScannerService: Sending frame to WebSocket (${base64Image.length} bytes base64)');
      
      final message = jsonEncode({
        'type': 'frame',
        'data': {
          'image': base64Image,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      });
      
      _channel!.sink.add(message);
      print('PlantScannerService: Frame sent successfully');
    } catch (e) {
      print('PlantScannerService: Failed to send frame: $e');
      _isConnected = false;
      throw e;
    }
  }
  
  /// Send ping to keep connection alive
  void sendPing() {
    if (!_isConnected || _channel == null) return;
    
    final message = jsonEncode({
      'type': 'ping',
      'data': {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    });
    
    _channel!.sink.add(message);
  }
  
  /// Scan single image using Go backend's /scan/image endpoint
  Future<Map<String, dynamic>?> scanSingleImage(String imagePath) async {
    try {
      print('PlantScannerService: Attempting to scan image at: $imagePath');
      
      // In development mode, return mock data when backend is not available
      if (AppConstants.isDevelopmentMode) {
        print('PlantScannerService: Development mode is enabled, using mock data');
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 2));
        
        // Return mock plant identification result
        final mockPlants = [
          {'prediction': 'Rose', 'confidence': 0.95},
          {'prediction': 'Sunflower', 'confidence': 0.88},
          {'prediction': 'Tulip', 'confidence': 0.92},
          {'prediction': 'Daisy', 'confidence': 0.85},
          {'prediction': 'Lily', 'confidence': 0.90},
        ];
        
        final randomPlant = mockPlants[DateTime.now().millisecond % mockPlants.length];
        print('PlantScannerService: Returning mock result - ${randomPlant['prediction']} (${randomPlant['confidence']})');
        return randomPlant;
      }
      
      print('PlantScannerService: Calling backend API for real scanning');
      final response = await _apiService.scanPlantImage(imagePath: imagePath);
      print('PlantScannerService: Backend API response: ${response.data}');
      return response.data;
    } catch (e) {
      print('PlantScannerService: Failed to scan single image: $e');
      
      // Fallback to mock data if real API fails
      if (AppConstants.isDevelopmentMode) {
        print('PlantScannerService: API failed, using development mode fallback');
        return {'prediction': 'Unknown Plant', 'confidence': 0.5};
      }
      
      throw Exception('Failed to scan image: $e');
    }
  }
  
  /// Listen to WebSocket messages from Go backend
  /// Expected response format: {"type": "prediction", "data": {"prediction": "Plant Name", "confidence": 0.85}}
  Stream<Map<String, dynamic>>? get messageStream {
    if (_channel == null) return null;
    
    return _channel!.stream.map((message) {
      try {
        return jsonDecode(message) as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing WebSocket message: $e');
        return <String, dynamic>{};
      }
    });
  }
  
  /// Close WebSocket connection
  void closeConnection() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      print('WebSocket connection closed');
    }
  }
  
  /// Check if WebSocket is connected
  bool get isConnected => _isConnected && _channel != null;
  
  /// Get connection status
  String get connectionStatus {
    if (_isConnected && _channel != null) {
      return 'Connected to Go backend';
    } else {
      return 'Disconnected';
    }
  }
  
  /// Test connection to Go backend
  Future<bool> testConnection() async {
    try {
      // Test HTTP endpoint first
      await _apiService.scanPlantImage(imagePath: 'test_connection');
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
