import 'dart:convert';
import 'dart:async';
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
  StreamController<Map<String, dynamic>>? _responseController;
  Timer? _pingTimer;
  
  PlantScannerService(this._apiService);
  
  /// Initialize WebSocket connection for live video streaming to Go backend
  Future<WebSocketChannel?> initializeWebSocket() async {
    try {
      // Close existing connection if any
      closeConnection();
      
      final wsUrl = '${AppConstants.webSocketUrl}${AppConstants.scanVideoEndpoint}';
      print('PlantScannerService: Attempting to connect to WebSocket: $wsUrl');
      
      _channel = IOWebSocketChannel.connect(
        wsUrl,
        connectTimeout: const Duration(seconds: 10),
        pingInterval: const Duration(seconds: 20),
      );
      
      // Initialize response stream controller
      _responseController = StreamController<Map<String, dynamic>>.broadcast();
      
      // Listen to WebSocket messages
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;
            print('PlantScannerService: Received WebSocket message: $data');
            _responseController?.add(data);
          } catch (e) {
            print('PlantScannerService: Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('PlantScannerService: WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('PlantScannerService: WebSocket connection closed');
          _isConnected = false;
        },
      );
      
      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Send initial ping to test connection
      try {
        final pingMessage = jsonEncode({
          'type': 'ping',
          'data': {'timestamp': DateTime.now().millisecondsSinceEpoch}
        });
        _channel!.sink.add(pingMessage);
        
        _isConnected = true;
        print('PlantScannerService: WebSocket connected successfully to Go backend');
        
        // Start periodic ping to keep connection alive
        _startPingTimer();
        
        return _channel;
      } catch (e) {
        print('PlantScannerService: Failed to send initial ping: $e');
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
  
  /// Start periodic ping timer
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        sendPing();
      } else {
        timer.cancel();
      }
    });
  }
  
  /// Send frame to Go backend for real-time analysis
  void sendFrame(String base64Image) {
    if (!_isConnected || _channel == null) {
      print('PlantScannerService: Cannot send frame - WebSocket not connected');
      return;
    }
    
    try {
      final message = jsonEncode({
        'type': 'frame',
        'data': {
          'image': base64Image,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      });
      
      _channel!.sink.add(message);
      print('PlantScannerService: Frame sent successfully (${base64Image.length} chars)');
    } catch (e) {
      print('PlantScannerService: Failed to send frame: $e');
      _isConnected = false;
    }
  }
  
  /// Send ping to keep connection alive
  void sendPing() {
    if (!_isConnected || _channel == null) return;
    
    try {
      final message = jsonEncode({
        'type': 'ping',
        'data': {'timestamp': DateTime.now().millisecondsSinceEpoch}
      });
      
      _channel!.sink.add(message);
      print('PlantScannerService: Ping sent');
    } catch (e) {
      print('PlantScannerService: Failed to send ping: $e');
      _isConnected = false;
    }
  }
  
  /// Scan single image using Go backend's /scan/image endpoint
  Future<Map<String, dynamic>?> scanSingleImage(String imagePath) async {
    try {
      print('PlantScannerService: Scanning single image via Go backend API');
      final response = await _apiService.scanPlantImage(imagePath: imagePath);
      
      if (response.statusCode == 200 && response.data != null) {
        print('PlantScannerService: Single image scan successful: ${response.data}');
        return response.data;
      } else {
        print('PlantScannerService: Single image scan failed with status: ${response.statusCode}');
        throw Exception('Backend returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('PlantScannerService: Failed to scan single image: $e');
      
      // Fallback to mock data only if in development mode
      if (AppConstants.isDevelopmentMode) {
        final mockPlants = [
          {'prediction': 'Marigold', 'confidence': 0.75},
          {'prediction': 'Scarlet Sage', 'confidence': 0.68},
          {'prediction': 'Rose', 'confidence': 0.85},
          {'prediction': 'Sunflower', 'confidence': 0.92},
        ];
        
        final randomPlant = mockPlants[DateTime.now().millisecond % mockPlants.length];
        print('PlantScannerService: Returning mock result - ${randomPlant['prediction']} (${randomPlant['confidence']})');
        return randomPlant;
      }
      
      throw Exception('Failed to scan image: $e');
    }
  }
  
  /// Listen to WebSocket messages from Go backend
  Stream<Map<String, dynamic>>? get messageStream {
    return _responseController?.stream;
  }
  
  /// Close WebSocket connection
  void closeConnection() {
    print('PlantScannerService: Closing WebSocket connection');
    
    _pingTimer?.cancel();
    _pingTimer = null;
    
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
    }
    
    _responseController?.close();
    _responseController = null;
    
    print('PlantScannerService: WebSocket connection closed');
  }
  
  /// Check if WebSocket is connected
  bool get isConnected => _isConnected && _channel != null;
  
  /// Get connection status
  String get connectionStatus {
    if (_isConnected && _channel != null) {
      return 'Connected to Go backend';
    } else {
      return 'Disconnected - Using fallback mode';
    }
  }
  
  /// Test connection to Go backend
  Future<bool> testConnection() async {
    try {
      print('PlantScannerService: Testing connection to Go backend');
      // Use health check endpoint instead of scan endpoint for testing
      final response = await _apiService.checkHealth();
      final isConnected = response.statusCode == 200;
      print('PlantScannerService: Connection test result: $isConnected');
      return isConnected;
    } catch (e) {
      print('PlantScannerService: Connection test failed: $e');
      return false;
    }
  }
}