import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../models/verification.dart';
import '../providers/verification_provider.dart';
import '../providers/user_provider.dart';
import '../plant_discovery/services/plant_correction_service.dart';

/// Community Verification Screen - Where users verify low-confidence plant identifications
class CommunityVerificationScreen extends StatefulWidget {
  const CommunityVerificationScreen({super.key});

  @override
  State<CommunityVerificationScreen> createState() =>
      _CommunityVerificationScreenState();
}

class _CommunityVerificationScreenState
    extends State<CommunityVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeProvider();
  }

  void _initializeProvider() async {
    final userProvider = context.read<UserProvider>();
    final verificationProvider = context.read<VerificationProvider>();
    verificationProvider.initialize(userProvider.deviceId);
    // Mark all pending verifications as seen when screen opens (clears badge)
    await verificationProvider.markAllAsSeen();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Community Verification',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<VerificationProvider>(
            builder: (context, provider, _) {
              if (provider.pendingCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.pendingCount}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Verify Others', icon: Icon(Icons.how_to_vote_rounded)),
            Tab(text: 'My Votes', icon: Icon(Icons.thumb_up_rounded)),
            Tab(text: 'My Submissions', icon: Icon(Icons.history_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVerifyOthersTab(),
          _buildMyVotesTab(),
          _buildMySubmissionsTab(),
        ],
      ),
    );
  }

  Widget _buildVerifyOthersTab() {
    return Consumer<VerificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (provider.pendingVerifications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.verified_rounded,
            title: 'All caught up!',
            subtitle: 'No plants waiting for verification',
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.pendingVerifications.length,
            itemBuilder: (context, index) {
              final item = provider.pendingVerifications[index];
              return _VerificationCard(
                treasureData: item['treasure'] as Map<String, dynamic>,
                treasureId: item['treasureId'] as String,
                verification: item['verification'] as TreasureVerification?,
                onVote: (isUpvote) async {
                  final success = await provider.submitVote(
                    treasureId: item['treasureId'] as String,
                    isUpvote: isUpvote,
                  );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isUpvote ? '👍 Upvoted!' : '👎 Downvoted',
                        ),
                        backgroundColor: isUpvote
                            ? AppColors.success
                            : Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyVotesTab() {
    return Consumer<VerificationProvider>(
      builder: (context, provider, _) {
        if (provider.userVotes.isEmpty) {
          return _buildEmptyState(
            icon: Icons.thumb_up_rounded,
            title: 'No votes yet',
            subtitle: 'Plants you vote on will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.userVotes.length,
          itemBuilder: (context, index) {
            final item = provider.userVotes[index];
            return _SubmissionCard(
              treasureData: item['treasure'] as Map<String, dynamic>,
              verification: item['verification'] as TreasureVerification?,
            );
          },
        );
      },
    );
  }

  Widget _buildMySubmissionsTab() {
    return Consumer<VerificationProvider>(
      builder: (context, provider, _) {
        // User submissions are now loaded via stream in provider.initialize()
        // No need for manual loading with addPostFrameCallback

        if (provider.userSubmissions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.spa_rounded,
            title: 'No submissions yet',
            subtitle: 'Your low-confidence discoveries will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.userSubmissions.length,
          itemBuilder: (context, index) {
            final item = provider.userSubmissions[index];
            return _SubmissionCard(
              treasureData: item['treasure'] as Map<String, dynamic>,
              verification: item['verification'] as TreasureVerification?,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for displaying a pending verification
class _VerificationCard extends StatefulWidget {
  final Map<String, dynamic> treasureData;
  final String treasureId;
  final TreasureVerification? verification;
  final Function(bool isUpvote) onVote;

  const _VerificationCard({
    required this.treasureData,
    required this.treasureId,
    required this.verification,
    required this.onVote,
  });

  @override
  State<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends State<_VerificationCard> {
  bool _showCorrectionPanel = false;
  bool _knowsPlantName = false;
  final TextEditingController _plantNameController = TextEditingController();
  final PlantCorrectionService _correctionService = PlantCorrectionService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _plantNameController.dispose();
    super.dispose();
  }

  void _handleNoWrongPressed() {
    setState(() {
      _showCorrectionPanel = true;
    });
  }

  void _handleCancelCorrection() {
    setState(() {
      _showCorrectionPanel = false;
      _knowsPlantName = false;
      _plantNameController.clear();
    });
  }

  Future<void> _handleSubmitCorrection() async {
    if (_plantNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the plant name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final correctorName = userProvider.userName.isEmpty
          ? 'Explorer'
          : userProvider.userName;

      await _correctionService.submitCorrection(
        originalTreasureId: widget.treasureId,
        originalPlantName:
            widget.treasureData['plantName'] ??
            widget.treasureData['commonName'] ??
            'Unknown',
        correctedPlantName: _plantNameController.text.trim(),
        correctedBy: userProvider.deviceId,
        correctedByName: correctorName,
        originalDiscoveredBy: widget.treasureData['deviceId'] ?? '',
        originalDiscoveredByName: widget.treasureData['userName'] ?? 'Explorer',
        originalConfidence: (widget.treasureData['confidence'] ?? 0.0)
            .toDouble(),
        imageBase64: widget.treasureData['imageBase64'],
        latitude: widget.treasureData['latitude']?.toDouble(),
        longitude: widget.treasureData['longitude']?.toDouble(),
      );

      // Also submit a downvote for the original
      await widget.onVote(false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌿 Correction submitted for community review!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        setState(() {
          _showCorrectionPanel = false;
          _knowsPlantName = false;
          _plantNameController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit correction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleDontKnowPlant() async {
    // Just downvote without providing a correction
    await widget.onVote(false);
    setState(() {
      _showCorrectionPanel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final plantName =
        widget.treasureData['commonName'] ??
        widget.treasureData['name'] ??
        'Unknown';
    final scientificName = widget.treasureData['plantName'] ?? '';
    final confidence = (widget.treasureData['confidence'] ?? 0.0) as double;
    final imageBase64 =
        widget.treasureData['imageBase64'] ??
        widget.treasureData['imageUrl'] ??
        '';
    final userName = widget.treasureData['userName'] ?? 'Explorer';
    final discoveredAt = (widget.treasureData['discoveredAt'] as Timestamp?)
        ?.toDate();
    final upvotes = widget.verification?.upvotes ?? 0;
    final downvotes = widget.verification?.downvotes ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _buildImage(imageBase64),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plant name and confidence
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plantName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (scientificName.isNotEmpty &&
                              scientificName != plantName)
                            Text(
                              scientificName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Confidence badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(
                          confidence,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(confidence * 100).toStringAsFixed(0)}% conf.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getConfidenceColor(confidence),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Discoverer info
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Discovered by $userName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (discoveredAt != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(discoveredAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Current votes display
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.thumb_up,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$upvotes',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.thumb_down,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$downvotes',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${4 - upvotes} more to verify',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Question prompt
                const Text(
                  'Is this identification correct?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                // Vote buttons or correction panel
                if (!_showCorrectionPanel)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => widget.onVote(true),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Yes, Correct'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleNoWrongPressed,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('No, Wrong'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  _buildCorrectionPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Do you know the correct plant name?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _handleCancelCorrection,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (!_knowsPlantName)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _knowsPlantName = true;
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Yes, I know'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleDontKnowPlant,
                    icon: const Icon(Icons.help_outline),
                    label: const Text("No, I don't"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            TextField(
              controller: _plantNameController,
              decoration: InputDecoration(
                hintText: 'Enter the correct plant name',
                prefixIcon: const Icon(Icons.eco, color: Colors.green),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleCancelCorrection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmitCorrection,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              '💡 Your correction will be reviewed by the community. If approved, you\'ll be credited as the identifier!',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImage(String imageBase64) {
    if (imageBase64.isEmpty || imageBase64 == 'placeholder') {
      return Container(
        height: 200,
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        child: const Center(
          child: Icon(Icons.eco, size: 64, color: AppColors.primary),
        ),
      );
    }

    try {
      final bytes = base64Decode(imageBase64);
      return Image.memory(
        Uint8List.fromList(bytes),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: AppColors.primaryLight.withValues(alpha: 0.2),
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    } catch (e) {
      return Container(
        height: 200,
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        child: const Center(
          child: Icon(Icons.eco, size: 64, color: AppColors.primary),
        ),
      );
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.6) return Colors.green;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Card for displaying user's own submission
class _SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> treasureData;
  final TreasureVerification? verification;

  const _SubmissionCard({
    required this.treasureData,
    required this.verification,
  });

  @override
  Widget build(BuildContext context) {
    final plantName =
        treasureData['commonName'] ?? treasureData['name'] ?? 'Unknown';
    final confidence = (treasureData['confidence'] ?? 0.0) as double;
    final imageBase64 =
        treasureData['imageBase64'] ?? treasureData['imageUrl'] ?? '';
    final status = verification?.status ?? VerificationStatus.pending;
    final upvotes = verification?.upvotes ?? 0;
    final downvotes = verification?.downvotes ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: _buildThumbnail(imageBase64),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant name
                  Text(
                    plantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Confidence
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}% confidence',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Status and votes
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(status.color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              status.emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(status.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (status == VerificationStatus.pending)
                        Text(
                          '👍$upvotes 👎$downvotes',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String imageBase64) {
    if (imageBase64.isEmpty || imageBase64 == 'placeholder') {
      return Container(
        width: 80,
        height: 80,
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        child: const Icon(Icons.eco, size: 32, color: AppColors.primary),
      );
    }

    try {
      final bytes = base64Decode(imageBase64);
      return Image.memory(
        Uint8List.fromList(bytes),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 80,
          height: 80,
          color: AppColors.primaryLight.withValues(alpha: 0.2),
          child: const Icon(Icons.eco, size: 32, color: AppColors.primary),
        ),
      );
    } catch (e) {
      return Container(
        width: 80,
        height: 80,
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        child: const Icon(Icons.eco, size: 32, color: AppColors.primary),
      );
    }
  }
}
