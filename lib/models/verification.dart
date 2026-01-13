import 'package:cloud_firestore/cloud_firestore.dart';

/// Verification status for plant discoveries
enum VerificationStatus {
  /// Automatically verified (confidence >= 60%)
  autoVerified,

  /// Pending community verification (confidence < 60%)
  pending,

  /// Verified by community (4+ upvotes)
  verified,

  /// Rejected by community (2+ downvotes)
  rejected,
}

/// Extension methods for VerificationStatus
extension VerificationStatusExtension on VerificationStatus {
  String get displayName {
    switch (this) {
      case VerificationStatus.autoVerified:
        return 'Auto-Verified';
      case VerificationStatus.pending:
        return 'Pending Verification';
      case VerificationStatus.verified:
        return 'Community Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }

  String get emoji {
    switch (this) {
      case VerificationStatus.autoVerified:
        return '✅';
      case VerificationStatus.pending:
        return '⏳';
      case VerificationStatus.verified:
        return '🏆';
      case VerificationStatus.rejected:
        return '❌';
    }
  }

  int get color {
    switch (this) {
      case VerificationStatus.autoVerified:
        return 0xFF4CAF50; // Green
      case VerificationStatus.pending:
        return 0xFFFF9800; // Orange
      case VerificationStatus.verified:
        return 0xFF2196F3; // Blue
      case VerificationStatus.rejected:
        return 0xFFF44336; // Red
    }
  }

  static VerificationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'autoverified':
      case 'auto_verified':
        return VerificationStatus.autoVerified;
      case 'pending':
        return VerificationStatus.pending;
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }
}

/// Verification data for a treasure
class TreasureVerification {
  final String treasureId;
  final int upvotes;
  final int downvotes;
  final List<String> voterIds;
  final VerificationStatus status;
  final DateTime? verifiedAt;
  final String? verifiedBy; // User who cast the deciding vote

  const TreasureVerification({
    required this.treasureId,
    this.upvotes = 0,
    this.downvotes = 0,
    this.voterIds = const [],
    this.status = VerificationStatus.pending,
    this.verifiedAt,
    this.verifiedBy,
  });

  /// Check if a user has already voted
  bool hasVoted(String userId) => voterIds.contains(userId);

  /// Total votes
  int get totalVotes => upvotes + downvotes;

  /// Approval percentage
  double get approvalRate => totalVotes > 0 ? upvotes / totalVotes : 0;

  factory TreasureVerification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TreasureVerification(
      treasureId: doc.id,
      upvotes: data['upvotes'] ?? 0,
      downvotes: data['downvotes'] ?? 0,
      voterIds: List<String>.from(data['voterIds'] ?? []),
      status: VerificationStatusExtension.fromString(
        data['status'] ?? 'pending',
      ),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      verifiedBy: data['verifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'upvotes': upvotes,
      'downvotes': downvotes,
      'voterIds': voterIds,
      'status': status.name,
      if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
      if (verifiedBy != null) 'verifiedBy': verifiedBy,
    };
  }

  TreasureVerification copyWith({
    String? treasureId,
    int? upvotes,
    int? downvotes,
    List<String>? voterIds,
    VerificationStatus? status,
    DateTime? verifiedAt,
    String? verifiedBy,
  }) {
    return TreasureVerification(
      treasureId: treasureId ?? this.treasureId,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      voterIds: voterIds ?? this.voterIds,
      status: status ?? this.status,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }
}

/// A vote cast by a user
class VerificationVote {
  final String odId;
  final String oderId;
  final bool isUpvote;
  final DateTime votedAt;

  const VerificationVote({
    required this.odId,
    required this.oderId,
    required this.isUpvote,
    required this.votedAt,
  });

  factory VerificationVote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VerificationVote(
      odId: doc.id,
      oderId: data['oderId'] ?? '',
      isUpvote: data['isUpvote'] ?? true,
      votedAt: (data['votedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'oderId': oderId,
      'isUpvote': isUpvote,
      'votedAt': Timestamp.fromDate(votedAt),
    };
  }
}
