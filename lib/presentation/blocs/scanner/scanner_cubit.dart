import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/presentation/blocs/scanner/scanner_state.dart';

@injectable
class ScannerCubit extends Cubit<ScannerState> {
  final ApiService _apiService;
  
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  bool _isStreaming = false;
  String? _sessionId;

  ScannerCubit(this._apiService) : super(ScannerInitial());

  Future<void> initializeScanner() async {
    try {
      emit(ScannerInitializing());
      
      // Initialize camera
      await _initializeCamera();
      
      // Initialize socket connection
      _initializeSocket();
      
      emit(ScannerReady());
    } catch (e) {
      emit(ScannerError(message: 'Failed to initialize scanner: $e'));
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }
    
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    await _cameraController!.initialize();
  }

  void _initializeSocket() {
    try {
      // Connect to Go WebSocket backend
      // Update this URL to your actual backend server when deployed
      _channel = IOWebSocketChannel.connect('ws://localhost:8080/ws');
      
      // Listen to messages from the WebSocket
      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          emit(ScannerError(message: 'WebSocket error: $error'));
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      emit(ScannerError(message: 'Failed to connect to WebSocket: $e'));
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final messageType = data['type'] as String?;
    
    switch (messageType) {
      case 'plant_identified':
        final plantName = data['plantName'] as String? ?? 'Unknown Plant';  // camelCase from Go backend
        final confidence = (data['confidence'] ?? 0.0).toDouble();
        
        emit(ScannerSuccess(
          plantName: plantName,
          confidence: confidence,
          imageUrl: null, // Go backend doesn't send image URL in current implementation
        ));
        
        stopScanning();
        break;
        
      case 'scanning_progress':
        final confidence = (data['confidence'] ?? 0.0).toDouble();
        emit(ScannerScanning(confidence: confidence));
        break;
        
      case 'error':
        emit(ScannerError(message: data['message'] ?? 'Scanner error occurred'));
        stopScanning();
        break;
        
      default:
        print('Unknown message type: $messageType');
    }
  }

  Future<void> startScanning() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      emit(const ScannerError(message: 'Camera not initialized'));
      return;
    }

    try {
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Start scanning session on backend
      await _apiService.startPlantScanning(sessionId: _sessionId!);
      
      emit(const ScannerScanning(confidence: 0.0));
      _isStreaming = true;
      _startFrameStreaming();
    } catch (e) {
      emit(ScannerError(message: 'Failed to start scanning: $e'));
    }
  }

  void _startFrameStreaming() async {
    if (!_isStreaming || _cameraController == null || _sessionId == null || _channel == null) return;
    
    try {
      final image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Send frame via WebSocket for real-time processing
      // Format matches Go backend's expected message structure exactly
      final message = jsonEncode({
        'type': 'video_frame',
        'sessionId': _sessionId,          // camelCase to match Go backend
        'frame': base64Image,             // 'frame' field name to match Go backend
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      _channel!.sink.add(message);
      
      // Continue streaming at 2 FPS
      if (_isStreaming) {
        Future.delayed(const Duration(milliseconds: 500), _startFrameStreaming);
      }
    } catch (e) {
      print('Error streaming frame: $e');
    }
  }

  Future<void> stopScanning() async {
    _isStreaming = false;
    
    if (_sessionId != null) {
      try {
        await _apiService.stopPlantScanning(sessionId: _sessionId!);
      } catch (e) {
        print('Error stopping scanning session: $e');
      }
      _sessionId = null;
    }
    
    emit(ScannerReady());
  }

  void resetScanner() {
    stopScanning();
    emit(ScannerReady());
  }

  CameraController? get cameraController => _cameraController;
  bool get isStreaming => _isStreaming;

  @override
  Future<void> close() {
    _cameraController?.dispose();
    _channel?.sink.close();
    return super.close();
  }
}
