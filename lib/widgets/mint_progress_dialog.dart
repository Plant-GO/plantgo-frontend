import 'dart:convert';
import 'package:flutter/material.dart';
import '../blockchain/blockchain.dart';
import '../services/nft_minting_service.dart';
import '../core/theme/app_colors.dart';

/// Dialog showing NFT minting progress and result.
///
/// Shows step-by-step progress during minting and celebration on success.
class MintProgressDialog extends StatefulWidget {
  final String plantName;
  final String? scientificName;
  final String? imageUrl;
  final String? imageBase64;
  final String? habitat;
  final String? region;
  final String? waterCare;
  final String? lightCare;
  final int? xpReward;
  final bool isNewDiscovery;
  final Future<MintResult> mintFuture;
  final VoidCallback? onComplete;

  const MintProgressDialog({
    super.key,
    required this.plantName,
    this.scientificName,
    this.imageUrl,
    this.imageBase64,
    this.habitat,
    this.region,
    this.waterCare,
    this.lightCare,
    this.xpReward,
    this.isNewDiscovery = false,
    required this.mintFuture,
    this.onComplete,
  });

  /// Show the mint progress dialog
  static Future<MintResult?> show({
    required BuildContext context,
    required String plantName,
    String? scientificName,
    String? imageUrl,
    String? imageBase64,
    String? habitat,
    String? region,
    String? waterCare,
    String? lightCare,
    int? xpReward,
    bool isNewDiscovery = false,
    required Future<MintResult> mintFuture,
    VoidCallback? onComplete,
  }) {
    return showDialog<MintResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MintProgressDialog(
        plantName: plantName,
        scientificName: scientificName,
        imageUrl: imageUrl,
        imageBase64: imageBase64,
        habitat: habitat,
        region: region,
        waterCare: waterCare,
        lightCare: lightCare,
        xpReward: xpReward,
        isNewDiscovery: isNewDiscovery,
        mintFuture: mintFuture,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<MintProgressDialog> createState() => _MintProgressDialogState();
}

class _MintProgressDialogState extends State<MintProgressDialog>
    with TickerProviderStateMixin {
  MintingStep _currentStep = MintingStep.preparing;
  MintResult? _result;
  String? _errorMessage;
  late AnimationController _celebrationController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _startMinting();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _startMinting() async {
    try {
      // Step 1: Preparing
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _currentStep = MintingStep.sending);

      // Step 2: Sending to blockchain
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _currentStep = MintingStep.minting);

      // Step 3: Wait for actual minting
      final result = await widget.mintFuture;

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _currentStep = MintingStep.complete;
          _result = result;
        });
        _celebrationController.forward();
      } else {
        setState(() {
          _currentStep = MintingStep.error;
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentStep = MintingStep.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // For success state, show the full celebration dialog
    if (_currentStep == MintingStep.complete) {
      return _buildSuccessDialog(screenHeight);
    }

    // For progress and error states, show compact dialog
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (_currentStep == MintingStep.error)
              _buildError()
            else
              _buildProgress(),
            const SizedBox(height: 24),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDialog(double screenHeight) {
    final nft = _result?.nftCard;
    final primaryColor = Color(nft?.rarity.primaryColor ?? 0xFFD53F8C);
    final secondaryColor = Color(nft?.rarity.secondaryColor ?? 0xFFF687B3);
    final isLegendary = nft?.rarity.isLegendary ?? false;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
          maxWidth: 400,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Gradient background
              _buildGradientBackground(primaryColor, secondaryColor),

              // Shimmer overlay for legendary
              if (isLegendary) _buildShimmerOverlay(primaryColor),

              // Content
              _buildSuccessContent(nft, primaryColor, secondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBackground(Color primaryColor, Color secondaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withOpacity(0.15),
            secondaryColor.withOpacity(0.08),
            Colors.white,
            Colors.white,
          ],
          stops: const [0.0, 0.25, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildShimmerOverlay(Color primaryColor) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: [
                    _shimmerController.value - 0.3,
                    _shimmerController.value,
                    _shimmerController.value + 0.3,
                  ].map((s) => s.clamp(0.0, 1.0)).toList(),
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: Container(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessContent(
    NFTCard? nft,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _celebrationController,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // New Discovery Badge
              if (widget.isNewDiscovery) ...[
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildNewDiscoveryBadge(primaryColor),
                ),
                const SizedBox(height: 16),
              ],

              // Title
              Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildTitleSection(primaryColor),
                ),
              ),

              const SizedBox(height: 24),

              // Plant Image Card
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildPlantImageCard(nft, primaryColor, secondaryColor),
              ),

              const SizedBox(height: 20),

              // Rarity Badge
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildRarityBadge(nft, primaryColor),
              ),

              const SizedBox(height: 16),

              // Plant Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildPlantNameSection(),
              ),

              const SizedBox(height: 20),

              // Care Info Stats
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildCareInfoRow(nft),
              ),

              const SizedBox(height: 24),

              // Description Text
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildDescriptionText(nft),
              ),

              const SizedBox(height: 24),

              // Action Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildAwesomeButton(primaryColor),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNewDiscoveryBadge(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            'NEW DISCOVERY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(Color primaryColor) {
    final nft = _result?.nftCard;
    final isLegendary = nft?.rarity.isLegendary ?? false;

    return Column(
      children: [
        const Text(
          'You found a',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: isLegendary
                  ? [primaryColor, primaryColor.withOpacity(0.7)]
                  : [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            ).createShader(bounds);
          },
          child: Text(
            isLegendary ? 'Rare Specimen!' : 'New Plant!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlantImageCard(
    NFTCard? nft,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.12),
            secondaryColor.withOpacity(0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Plant Image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _buildPlantImage(),
          ),

          // First Find Badge
          if (widget.isNewDiscovery)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'FIRST FIND!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlantImage() {
    // Try imageBase64 first, then imageUrl, then placeholder
    if (widget.imageBase64 != null && widget.imageBase64!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(widget.imageBase64!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        );
      } catch (_) {
        return _buildImagePlaceholder();
      }
    }

    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImagePlaceholder(isLoading: true);
        },
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder({bool isLoading = false}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              )
            : Icon(
                Icons.eco_rounded,
                size: 64,
                color: AppColors.primary.withOpacity(0.4),
              ),
      ),
    );
  }

  Widget _buildRarityBadge(NFTCard? nft, Color primaryColor) {
    final displayName = nft?.rarity.displayName ?? 'Common';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        displayName,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPlantNameSection() {
    final habitat = widget.habitat;
    final region = widget.region;
    final locationText = [
      habitat,
      region,
    ].where((s) => s != null && s.isNotEmpty).join(' • ');

    return Column(
      children: [
        Text(
          widget.plantName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        if (locationText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            locationText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCareInfoRow(NFTCard? nft) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCareChip(
          icon: Icons.water_drop_rounded,
          label: 'WATER',
          value: widget.waterCare ?? 'Med',
          iconColor: Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildCareChip(
          icon: Icons.wb_sunny_rounded,
          label: 'LIGHT',
          value: widget.lightCare ?? 'Bright',
          iconColor: Colors.orange,
        ),
        const SizedBox(width: 12),
        _buildCareChip(
          icon: Icons.emoji_events_rounded,
          label: 'XP',
          value: '+${widget.xpReward ?? 50}',
          iconColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildCareChip({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionText(NFTCard? nft) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Your plant discovery has been minted as an NFT! Check your collection to view it.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildAwesomeButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          widget.onComplete?.call();
          Navigator.of(context).pop(_result);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Awesome!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    IconData icon;
    Color color;

    switch (_currentStep) {
      case MintingStep.preparing:
      case MintingStep.sending:
      case MintingStep.minting:
        title = 'Minting NFT';
        icon = Icons.auto_awesome;
        color = const Color(0xFF9945FF);
        break;
      case MintingStep.complete:
        title = 'NFT Minted!';
        icon = Icons.celebration;
        color = const Color(0xFF14F195);
        break;
      case MintingStep.error:
        title = 'Minting Failed';
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.plantName,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        _buildStepIndicator(
          step: MintingStep.preparing,
          label: 'Preparing transaction',
        ),
        _buildStepConnector(MintingStep.preparing),
        _buildStepIndicator(
          step: MintingStep.sending,
          label: 'Sending to blockchain',
        ),
        _buildStepConnector(MintingStep.sending),
        _buildStepIndicator(
          step: MintingStep.minting,
          label: 'Minting your NFT',
        ),
      ],
    );
  }

  Widget _buildStepIndicator({
    required MintingStep step,
    required String label,
  }) {
    final isActive = _currentStep.index >= step.index;
    final isCurrent = _currentStep == step;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF9945FF) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: isCurrent
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  isActive ? Icons.check : Icons.circle,
                  color: isActive ? Colors.white : Colors.grey[400],
                  size: 16,
                ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey[400],
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(MintingStep afterStep) {
    final isActive = _currentStep.index > afterStep.index;

    return Container(
      margin: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: isActive ? const Color(0xFF9945FF) : Colors.grey[200],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        ),

        const SizedBox(height: 16),

        Text(
          _errorMessage ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_currentStep == MintingStep.error) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Close', style: TextStyle(color: Colors.black87)),
        ),
      );
    }

    // Minting in progress - no button
    return const SizedBox.shrink();
  }
}

/// Minting progress steps
enum MintingStep { preparing, sending, minting, complete, error }
