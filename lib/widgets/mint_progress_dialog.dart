import 'package:flutter/material.dart';
import '../blockchain/blockchain.dart';
import '../services/nft_minting_service.dart';

/// Dialog showing NFT minting progress and result.
/// 
/// Shows step-by-step progress during minting and celebration on success.
class MintProgressDialog extends StatefulWidget {
  final String plantName;
  final String? imageUrl;
  final Future<MintResult> mintFuture;
  final VoidCallback? onComplete;

  const MintProgressDialog({
    super.key,
    required this.plantName,
    this.imageUrl,
    required this.mintFuture,
    this.onComplete,
  });

  /// Show the mint progress dialog
  static Future<MintResult?> show({
    required BuildContext context,
    required String plantName,
    String? imageUrl,
    required Future<MintResult> mintFuture,
    VoidCallback? onComplete,
  }) {
    return showDialog<MintResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MintProgressDialog(
        plantName: plantName,
        imageUrl: imageUrl,
        mintFuture: mintFuture,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<MintProgressDialog> createState() => _MintProgressDialogState();
}

class _MintProgressDialogState extends State<MintProgressDialog>
    with SingleTickerProviderStateMixin {
  MintingStep _currentStep = MintingStep.preparing;
  MintResult? _result;
  String? _errorMessage;
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _startMinting();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
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
            // Header
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Progress or result
            if (_currentStep == MintingStep.complete)
              _buildSuccess()
            else if (_currentStep == MintingStep.error)
              _buildError()
            else
              _buildProgress(),
            
            const SizedBox(height: 24),
            
            // Action button
            _buildActionButton(),
          ],
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
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
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

  Widget _buildSuccess() {
    final nft = _result?.nftCard;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          // Success animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(nft?.rarity.primaryColor ?? 0xFF14F195),
                  Color(nft?.rarity.secondaryColor ?? 0xFF9945FF),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Card info
          if (nft != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(nft.rarity.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                nft.rarity.displayName,
                style: TextStyle(
                  color: Color(nft.rarity.primaryColor),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Congratulations! 🎉',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              'Your ${nft.rarity.rarityTier} card has been minted',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
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
          child: const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 40,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          _errorMessage ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_currentStep == MintingStep.complete) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                if (_result?.explorerUrl != null) {
                  // Open Solana Explorer - could use url_launcher
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View on Explorer'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                widget.onComplete?.call();
                Navigator.of(context).pop(_result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14F195),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      );
    }
    
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
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.black87),
          ),
        ),
      );
    }
    
    // Minting in progress - no button
    return const SizedBox.shrink();
  }
}

/// Minting progress steps
enum MintingStep {
  preparing,
  sending,
  minting,
  complete,
  error,
}
