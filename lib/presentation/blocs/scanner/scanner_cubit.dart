import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:camera/camera.dart';
import 'package:plantgo/services/plant_scanner_service.dart';
import 'package:plantgo/presentation/blocs/scanner/scanner_state.dart';

@injectable
class ScannerCubit extends Cubit<ScannerState> {
  final PlantScannerService _scannerService;
  
  CameraController? _cameraController;
  bool _isStreaming = false;
  String? _sessionId;

  ScannerCubit(this._scannerService) : super(ScannerInitial());

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
      // Use the scanner service to initialize WebSocket connection
      _scannerService.initializeWebSocket().then((channel) {
        if (channel != null) {
          // Listen to messages from the WebSocket using the service
          final messageStream = _scannerService.messageStream;
          if (messageStream != null) {
            messageStream.listen(
              (data) => _handleWebSocketMessage(data),
              onError: (error) {
                print('WebSocket stream error: $error');
                // Don't emit error here, just log it
              },
              onDone: () {
                print('WebSocket connection closed');
              },
            );
          }
          print('Scanner: WebSocket mode enabled for live scanning');
        } else {
          print('Scanner: WebSocket connection failed, using HTTP mode only');
          // Don't emit error, just continue without WebSocket
        }
      }).catchError((error) {
        print('Scanner: WebSocket initialization failed: $error');
        // Don't emit error, the app can still work with HTTP scanning
      });
    } catch (e) {
      print('Scanner: Failed to initialize WebSocket: $e');
      // Don't emit error, continue with HTTP-only mode
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final messageType = data['type'] as String?;
    
    switch (messageType) {
      case 'prediction':
        // Go backend sends: {"type": "prediction", "data": {"prediction": "Plant Name", "confidence": 0.85}}
        final predictionData = data['data'] as Map<String, dynamic>? ?? {};
        final plantName = predictionData['prediction'] as String? ?? 'Unknown Plant';
        final confidence = (predictionData['confidence'] ?? 0.0).toDouble();
        
        emit(ScannerSuccess(
          plantName: plantName,
          confidence: confidence,
          imageUrl: null,
        ));
        
        stopScanning();
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
      emit(const ScannerScanning(confidence: 0.0));
      
      print('Scanner: Starting scanning with session: $_sessionId');
      print('Scanner: WebSocket connected: ${_scannerService.isConnected}');
      
      if (_scannerService.isConnected) {
        // Use WebSocket for real-time scanning
        print('Scanner: Starting real-time WebSocket scanning');
        _isStreaming = true;
        _startFrameStreaming();
      } else {
        // Use single image scanning as fallback
        print('Scanner: WebSocket not available, using single image mode');
        await _captureSingleImage();
      }
    } catch (e) {
      print('Scanner: Failed to start scanning: $e');
      emit(ScannerError(message: 'Failed to start scanning: $e'));
    }
  }

  // Add method for single image capture when WebSocket is not available
  Future<void> _captureSingleImage() async {
    try {
      print('Scanner: Capturing single image for backend analysis');
      final image = await _cameraController!.takePicture();
      print('Scanner: Image captured at: ${image.path}');
      
      final data = await _scannerService.scanSingleImage(image.path);
      print('Scanner: Backend response: $data');
      
      if (data != null) {
        final plantName = data['prediction'] as String? ?? 'Unknown Plant';
        final confidence = (data['confidence'] ?? 0.0).toDouble();
        
        print('Scanner: Plant identified - $plantName (confidence: $confidence)');
        
        emit(ScannerSuccess(
          plantName: plantName,
          confidence: confidence,
          imageUrl: image.path,
        ));
      } else {
        print('Scanner: No response from server');
        emit(const ScannerError(message: 'No response from server'));
      }
    } catch (e) {
      print('Scanner: Failed to scan image: $e');
      emit(ScannerError(message: 'Failed to scan image: $e'));
    }
  }

  void _startFrameStreaming() async {
    if (!_isStreaming || _cameraController == null || _sessionId == null) {
      print('Scanner: Frame streaming stopped - streaming: $_isStreaming, camera: ${_cameraController != null}, session: $_sessionId');
      return;
    }
    
    // Check if WebSocket is still connected
    if (!_scannerService.isConnected) {
      print('Scanner: WebSocket disconnected during streaming, switching to single image mode');
      try {
        await _captureSingleImage();
        return;
      } catch (e) {
        print('Scanner: Single image fallback failed: $e');
        emit(const ScannerError(message: 'Connection lost. Please try again.'));
        stopScanning();
        return;
      }
    }
    
    try {
      print('Scanner: Capturing frame for WebSocket streaming');
      final image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      
      print('Scanner: Frame captured (${bytes.length} bytes), sending to WebSocket');
      
      // Send frame via the scanner service
      _scannerService.sendFrame(base64Image);
      
      // Continue streaming at 2 FPS
      if (_isStreaming && _scannerService.isConnected) {
        Future.delayed(const Duration(milliseconds: 500), _startFrameStreaming);
      } else {
        print('Scanner: Stopping frame streaming - streaming: $_isStreaming, connected: ${_scannerService.isConnected}');
      }
    } catch (e) {
      print('Scanner: Error streaming frame: $e');
      // If WebSocket isn't available, try single image scanning
      if (!_scannerService.isConnected) {
        print('Scanner: WebSocket failed, trying single image scanning');
        try {
          await _captureSingleImage();
        } catch (singleImageError) {
          print('Scanner: Single image scanning also failed: $singleImageError');
          emit(ScannerError(message: 'Scanning failed: $singleImageError'));
          stopScanning();
        }
      } else {
        // Continue trying if WebSocket is still connected
        if (_isStreaming) {
          Future.delayed(const Duration(milliseconds: 1000), _startFrameStreaming);
        }
      }
    }
  }

  Future<void> stopScanning() async {
    _isStreaming = false;
    
    // Go backend doesn't need explicit session stop - WebSocket disconnection handles it
    if (_sessionId != null) {
      print('Stopping scanning session: $_sessionId');
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

  // Single image scanning using Go backend's /scan/image endpoint
  Future<void> scanSingleImage(String imagePath) async {
    try {
      emit(ScannerScanning(confidence: 0.0));
      
      final data = await _scannerService.scanSingleImage(imagePath);
      
      if (data != null) {
        final plantName = data['prediction'] as String? ?? 'Unknown Plant';
        final confidence = (data['confidence'] ?? 0.0).toDouble();
        
        emit(ScannerSuccess(
          plantName: plantName,
          confidence: confidence,
          imageUrl: imagePath,
        ));
      } else {
        emit(const ScannerError(message: 'No response from server'));
      }
    } catch (e) {
      emit(ScannerError(message: 'Failed to scan image: $e'));
    }
  }

  @override
  Future<void> close() {
    _cameraController?.dispose();
    _scannerService.closeConnection();
    return super.close();
  }
}
