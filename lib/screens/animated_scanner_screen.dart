import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../core/theme/app_colors.dart';
import '../models/level.dart';
import '../services/plant_id_service.dart';

/// Animated Scanner Screen with live camera preview
/// Shows a scanning animation while capturing plant images
class AnimatedScannerScreen extends StatefulWidget {
  final Level level;
  final Function(bool success, String? plantName, String? imagePath)
  onScanComplete;

  const AnimatedScannerScreen({
    super.key,
    required this.level,
    required this.onScanComplete,
  });

  @override
  State<AnimatedScannerScreen> createState() => _AnimatedScannerScreenState();
}

class _AnimatedScannerScreenState extends State<AnimatedScannerScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isProcessing = false;
  String _statusMessage = 'Point camera at the plant';

  // Animation controllers
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _cornerController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _cornerAnimation;

  final PlantIdService _plantIdService = PlantIdService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    // Scan line moving up and down
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
    _scanLineController.repeat(reverse: true);

    // Pulse animation for corners
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Corner rotation animation
    _cornerController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _cornerAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _cornerController, curve: Curves.linear));
    _cornerController.repeat();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No camera available';
        });
        return;
      }

      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera error: $e';
      });
    }
  }

  Future<void> _captureAndIdentify() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isScanning = true;
      _isProcessing = true;
      _statusMessage = 'Scanning plant...';
    });

    try {
      // Capture the image
      final XFile imageFile = await _cameraController!.takePicture();
      final bytes = await File(imageFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        _statusMessage = 'Identifying plant...';
      });

      // Send to Plant.ID API
      final result = await _plantIdService.identifyPlant(base64Image);

      if (result.suggestions.isEmpty) {
        setState(() {
          _statusMessage = 'Could not identify plant. Try again.';
          _isScanning = false;
          _isProcessing = false;
        });
        return;
      }

      // Get common names from the API response
      final topSuggestion = result.suggestions.first;
      final commonNames = topSuggestion.commonNames;
      final scientificName = topSuggestion.plantName;

      // Check if it matches the expected plant
      final isMatch = SampleLevels.isPlantMatch(widget.level.plantToFindId, [
        ...commonNames,
        scientificName,
      ]);

      final displayName = commonNames.isNotEmpty
          ? commonNames.first
          : scientificName;

      if (isMatch) {
        setState(() {
          _statusMessage = '✅ Plant matched: $displayName!';
        });

        // Wait a moment to show success
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          widget.onScanComplete(true, displayName, imageFile.path);
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _statusMessage =
              '❌ Found: $displayName\n'
              'Expected: ${widget.level.plantToFindId.replaceAll('_', ' ').toUpperCase()}\n'
              'Try again!';
          _isScanning = false;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isScanning = false;
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _cornerController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview - Full Screen
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 100,
                  height: _cameraController!.value.previewSize?.width ?? 100,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // Scanner Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(
                scanProgress: _scanLineAnimation,
                pulseScale: _pulseAnimation,
                rotation: _cornerAnimation,
                isScanning: _isScanning,
              ),
            ),
          ),

          // Animated scan line
          if (_isCameraInitialized)
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                final scanAreaTop = MediaQuery.of(context).size.height * 0.2;
                final scanAreaHeight = MediaQuery.of(context).size.height * 0.5;
                final linePosition =
                    scanAreaTop + (scanAreaHeight * _scanLineAnimation.value);

                return Positioned(
                  top: linePosition,
                  left: 40,
                  right: 40,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withValues(alpha: 0.8),
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Level ${widget.level.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel with status and capture button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Capture button
                  GestureDetector(
                    onTap: _isProcessing ? null : _captureAndIdentify,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isProcessing ? 1.0 : _pulseAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isProcessing
                                  ? Colors.grey
                                  : AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_isProcessing
                                              ? Colors.grey
                                              : AppColors.primary)
                                          .withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isProcessing ? 'Processing...' : 'Tap to scan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay with animated corners
class ScannerOverlayPainter extends CustomPainter {
  final Animation<double> scanProgress;
  final Animation<double> pulseScale;
  final Animation<double> rotation;
  final bool isScanning;

  ScannerOverlayPainter({
    required this.scanProgress,
    required this.pulseScale,
    required this.rotation,
    required this.isScanning,
  }) : super(repaint: Listenable.merge([scanProgress, pulseScale, rotation]));

  @override
  void paint(Canvas canvas, Size size) {
    // Scan area dimensions
    final scanAreaWidth = size.width - 80;
    final scanAreaHeight = size.height * 0.5;
    final scanAreaTop = size.height * 0.2;
    final scanAreaLeft = 40.0;

    final scanRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaWidth, scanAreaHeight),
      const Radius.circular(20),
    );

    // No black overlay - just draw the scan frame

    // Draw animated corners
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0 * pulseScale.value;

    // Top-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      Offset(scanAreaLeft, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft + cornerLength, scanAreaTop),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth - cornerLength, scanAreaTop),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight - cornerLength),
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(
        scanAreaLeft + scanAreaWidth - cornerLength,
        scanAreaTop + scanAreaHeight,
      ),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(
        scanAreaLeft + scanAreaWidth,
        scanAreaTop + scanAreaHeight - cornerLength,
      ),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );

    // Draw scanning particles when active
    if (isScanning) {
      final particlePaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final random = math.Random(42);
      for (int i = 0; i < 20; i++) {
        final x = scanAreaLeft + random.nextDouble() * scanAreaWidth;
        final y = scanAreaTop + random.nextDouble() * scanAreaHeight;
        final particleProgress = (scanProgress.value + i * 0.05) % 1.0;
        final particleSize = 3.0 + particleProgress * 4;
        final alpha = (1 - particleProgress) * 0.5;

        canvas.drawCircle(
          Offset(x, y),
          particleSize,
          particlePaint..color = AppColors.primary.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) => true;
}
