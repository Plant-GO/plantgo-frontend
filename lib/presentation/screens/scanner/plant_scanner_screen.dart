import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:plantgo/configs/app_colors.dart';
import 'package:plantgo/presentation/blocs/scanner/scanner_cubit.dart';
import 'package:plantgo/presentation/blocs/scanner/scanner_state.dart';

class PlantScannerScreen extends StatefulWidget {
  const PlantScannerScreen({Key? key}) : super(key: key);

  @override
  State<PlantScannerScreen> createState() => _PlantScannerScreenState();
}

class _PlantScannerScreenState extends State<PlantScannerScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _scanAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _breatheAnimationController;
  late AnimationController _rippleAnimationController;
  late AnimationController _particleAnimationController;
  
  // Animations
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _breatheAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _particleAnimation;
  
  // Visual effects
  final List<Particle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateParticles();
    
    // Initialize scanner cubit
    context.read<ScannerCubit>().initializeScanner();
  }

  void _initializeAnimations() {
    // Scanning line animation - smooth back and forth with easing
    _scanAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    // Pulse animation for scan area - enhanced breathing effect
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOutSine,
    ));

    // Breathing animation for the corner indicators - slower and more elegant
    _breatheAnimationController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    _breatheAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breatheAnimationController,
      curve: Curves.easeInOutQuart,
    ));

    // Ripple effect animation - multiple waves
    _rippleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleAnimationController,
      curve: Curves.easeOut,
    ));

    // Particle animation - smoother movement
    _particleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleAnimationController,
      curve: Curves.linear,
    ));

    // Start continuous animations with staggered timing
    _breatheAnimationController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _particleAnimationController.repeat();
    });
  }

  void _generateParticles() {
    for (int i = 0; i < 25; i++) {
      _particles.add(Particle());
    }
  }

  void _startScanning() {
    // Start animations with staggered timing for better visual effect
    _scanAnimationController.repeat(reverse: true);
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _pulseAnimationController.repeat(reverse: true);
      }
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _rippleAnimationController.repeat();
      }
    });
    
    // Start scanning using the cubit
    context.read<ScannerCubit>().startScanning();
  }

  void _stopScanning() {
    _stopAllAnimations();
    context.read<ScannerCubit>().stopScanning();
  }

  void _stopAllAnimations() {
    _scanAnimationController.stop();
    _pulseAnimationController.stop();
    _rippleAnimationController.stop();
  }

  void _showSuccessAnimation() {
    // Enhanced success animation sequence
    _rippleAnimationController.reset();
    _rippleAnimationController.forward().then((_) {
      if (mounted) {
        // Create a celebratory burst effect
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _rippleAnimationController.reset();
            _rippleAnimationController.forward();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScannerCubit, ScannerState>(
      listener: (context, state) {
        if (state is ScannerSuccess) {
          _showSuccessAnimation();
        } else if (state is ScannerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ScannerInitial || state is ScannerInitializing) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Initializing Plant Scanner...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ScannerError) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scanner Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ScannerCubit>().initializeScanner();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final cameraController = context.read<ScannerCubit>().cameraController;
        final isScanning = state is ScannerScanning;
        final confidence = state is ScannerScanning ? state.confidence : 0.0;
        final scanResult = state is ScannerSuccess ? state : null;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Camera preview
              if (cameraController != null)
                Positioned.fill(
                  child: CameraPreview(cameraController),
                ),
              
              // Animated particles
              _buildParticleSystem(),
              
              // Scanning overlay with animations
              _buildScanningOverlay(isScanning, confidence),
              
              // Top controls
              _buildTopControls(),
              
              // Bottom controls
              _buildBottomControls(isScanning),
              
              // Scan result
              if (scanResult != null) _buildScanResult(scanResult),
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticleSystem() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ParticlePainter(_particles, _particleAnimation.value),
        );
      },
    );
  }

  Widget _buildScanningOverlay(bool isScanning, double confidence) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scanAnimation,
          _pulseAnimation,
          _breatheAnimation,
          _rippleAnimation,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
            ),
            child: Stack(
              children: [
                // Ripple effects
                if (isScanning) _buildRippleEffects(),
                
                // Main scan area
                Center(
                  child: Transform.scale(
                    scale: isScanning ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 280,
                      height: 280,
                      child: Stack(
                        children: [
                          // Outer glow effect
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          
                          // Main border
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isScanning 
                                    ? AppColors.primary.withOpacity(0.8)
                                    : Colors.white.withOpacity(0.6),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          
                          // Corner indicators with animation
                          ..._buildAnimatedCornerIndicators(isScanning),
                          
                          // Scanning line with enhanced effect
                          if (isScanning) _buildScanningLine(),
                          
                          // Progress indicator
                          if (isScanning && confidence > 0) _buildProgressIndicator(confidence),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Status text
                _buildStatusText(isScanning, confidence),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRippleEffects() {
    return Center(
      child: Container(
        width: 350,
        height: 350,
        child: CustomPaint(
          painter: RipplePainter(
            _rippleAnimation.value,
            AppColors.primary.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedCornerIndicators(bool isScanning) {
    final cornerSize = 45.0 * _breatheAnimation.value;
    final cornerThickness = 6.0;
    final cornerOpacity = 0.7 + (0.3 * _breatheAnimation.value);
    
    return [
      // Top-left with enhanced glow
      Positioned(
        top: -cornerThickness / 2,
        left: -cornerThickness / 2,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.accent.withOpacity(cornerOpacity),
                width: cornerThickness,
              ),
              left: BorderSide(
                color: AppColors.accent.withOpacity(cornerOpacity),
                width: cornerThickness,
              ),
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
      // Top-right with enhanced glow
      Positioned(
        top: -cornerThickness / 2,
        right: -cornerThickness / 2,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.accent.withOpacity(cornerOpacity),
                width: cornerThickness,
              ),
              right: BorderSide(
                color: AppColors.accent.withOpacity(cornerOpacity),
                width: cornerThickness,
              ),
            ),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
      // Bottom-left with enhanced glow
      Positioned(
        bottom: -cornerThickness / 2,
        left: -cornerThickness / 2,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.accent.withOpacity(cornerOpacity),
                width: cornerThickness,
              ),
              left: BorderSide(
                color: AppColors.accent.withOpacity(cornerOpacity),
                width: cornerThickness,
              ),
            ),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
      // Bottom-right with enhanced glow
      Positioned(
        bottom: -cornerThickness / 2,
        right: -cornerThickness / 2,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.accent.withOpacity(cornerOpacity),
                width: cornerThickness,
              ),
              right: BorderSide(
                color: AppColors.accent.withOpacity(cornerOpacity),
                width: cornerThickness,
              ),
            ),
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildScanningLine() {
    return Positioned(
      left: 10,
      right: 10,
      top: 10 + (_scanAnimation.value * 240),
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              AppColors.primary.withOpacity(0.2),
              AppColors.primary.withOpacity(0.5),
              AppColors.primary,
              AppColors.accent,
              AppColors.primary,
              AppColors.primary.withOpacity(0.5),
              AppColors.primary.withOpacity(0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.15, 0.3, 0.4, 0.5, 0.6, 0.7, 0.85, 1.0],
          ),
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.8),
              blurRadius: 12,
              spreadRadius: 3,
            ),
            BoxShadow(
              color: AppColors.accent.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double confidence) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: confidence,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Analyzing: ${(confidence * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText(bool isScanning, double confidence) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: 0,
      right: 0,
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              isScanning 
                  ? 'Scanning plant...' 
                  : 'Position plant in the scan area',
              key: ValueKey(isScanning),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!isScanning)
            const Text(
              'Tap the scan button to identify the plant',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildControlButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Plant Scanner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
          _buildControlButton(
            icon: Icons.flash_off,
            onPressed: () {
              // Toggle flashlight
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBottomControls(bool isScanning) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Scan button with enhanced animation
          GestureDetector(
            onTap: isScanning ? _stopScanning : _startScanning,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isScanning 
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: (isScanning ? Colors.red : AppColors.primary)
                        .withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isScanning ? Icons.stop : Icons.center_focus_strong,
                color: Colors.white,
                size: 45,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isScanning ? 'Tap to stop scanning' : 'Tap to start scanning',
              key: ValueKey(isScanning),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResult(ScannerSuccess scanResult) {
    return Positioned(
      bottom: 180,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.98),
              AppColors.accent.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 8,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.eco,
                color: Colors.white,
                size: 45,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Plant Identified!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scanResult.plantName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Confidence: ${(scanResult.confidence * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, {
                        'plantName': scanResult.plantName,
                        'confidence': scanResult.confidence,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: const Icon(Icons.add_location, size: 20),
                    label: const Text(
                      'Add to Map',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    context.read<ScannerCubit>().resetScanner();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Scan Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    _breatheAnimationController.dispose();
    _rippleAnimationController.dispose();
    _particleAnimationController.dispose();
    super.dispose();
  }
}

// Particle class for floating effects with enhanced properties
class Particle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late Color color;
  late double opacity;
  late double phase; // For sine wave movement
  late double direction; // Movement direction

  Particle() {
    reset();
  }

  void reset() {
    final random = DateTime.now().millisecondsSinceEpoch;
    x = (random % 1000) / 1000.0;
    y = (random % 1000) / 1000.0;
    size = 1.5 + (random % 4);
    speed = 0.3 + (random % 150) / 300.0;
    phase = (random % 100) / 100.0;
    direction = (random % 360) * 3.14159 / 180;
    opacity = 0.2 + (random % 60) / 100.0;
    
    // Create variety in particle colors
    final colorVariant = random % 3;
    switch (colorVariant) {
      case 0:
        color = AppColors.primary.withOpacity(opacity);
        break;
      case 1:
        color = AppColors.accent.withOpacity(opacity);
        break;
      default:
        color = Colors.white.withOpacity(opacity * 0.7);
    }
  }
}

// Custom painter for particle system with enhanced effects
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      paint.color = particle.color;
      
      // Enhanced movement with sine wave patterns
      final baseX = particle.x * size.width;
      final baseY = (particle.y + animationValue * particle.speed) % 1.0 * size.height;
      
      // Add subtle horizontal oscillation
      final oscillationX = baseX + (10 * math.sin((animationValue + particle.phase) * 2 * math.pi));
      final oscillationY = baseY + (5 * math.cos((animationValue + particle.phase) * 3 * math.pi));
      
      // Create varying opacity based on position
      final centerDistance = math.sqrt(
        math.pow(oscillationX - size.width / 2, 2) + 
        math.pow(oscillationY - size.height / 2, 2)
      );
      final maxDistance = math.sqrt(math.pow(size.width / 2, 2) + math.pow(size.height / 2, 2));
      final distanceOpacity = 1.0 - (centerDistance / maxDistance);
      
      paint.color = particle.color.withOpacity(
        particle.opacity * distanceOpacity * 0.8
      );
      
      // Draw particle with glow effect
      canvas.drawCircle(
        Offset(oscillationX, oscillationY),
        particle.size,
        paint,
      );
      
      // Add subtle glow
      paint.color = particle.color.withOpacity(
        particle.opacity * distanceOpacity * 0.3
      );
      canvas.drawCircle(
        Offset(oscillationX, oscillationY),
        particle.size * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for ripple effects with enhanced visuals
class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  RipplePainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Create multiple ripple waves with different properties
    for (int i = 0; i < 4; i++) {
      final rippleProgress = (animationValue + (i * 0.25)) % 1.0;
      final radius = maxRadius * rippleProgress;
      
      if (radius > 0) {
        // Outer ripple
        final outerPaint = Paint()
          ..color = color.withOpacity((1 - rippleProgress) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 - (rippleProgress * 2);

        canvas.drawCircle(center, radius, outerPaint);
        
        // Inner glow
        final glowPaint = Paint()
          ..color = color.withOpacity((1 - rippleProgress) * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 - (rippleProgress * 6);

        canvas.drawCircle(center, radius, glowPaint);
        
        // Pulsing dots around the ripple
        for (int j = 0; j < 8; j++) {
          final angle = (j * 45.0) * (math.pi / 180);
          final dotX = center.dx + (radius * 0.9) * math.cos(angle);
          final dotY = center.dy + (radius * 0.9) * math.sin(angle);
          
          final dotPaint = Paint()
            ..color = AppColors.accent.withOpacity((1 - rippleProgress) * 0.6)
            ..style = PaintingStyle.fill;
            
          canvas.drawCircle(
            Offset(dotX, dotY),
            2 * (1 - rippleProgress),
            dotPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
