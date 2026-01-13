import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for plant identification corrections submitted by community members
class PlantCorrection {
  final String id;
  final String originalTreasureId;
  final String originalPlantName;
  final String correctedPlantName;
  final String correctedBy;           // User who submitted the correction
  final String correctedByName;       // Display name of corrector
  final String originalDiscoveredBy;  // Original discoverer user ID
  final String originalDiscoveredByName; // Original discoverer display name
  final double originalConfidence;
  final String? imageBase64;
  final double? latitude;
  final double? longitude;
  final CorrectionStatus status;
  final int upvotes;
  final int downvotes;
  final List<String> voterIds;
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  
  // Threshold for community verification
  static const int upvotesRequired = 3;
  static const int downvotesRequired = 2;

  PlantCorrection({
    required this.id,
    required this.originalTreasureId,
    required this.originalPlantName,
    required this.correctedPlantName,
    required this.correctedBy,
    required this.correctedByName,
    required this.originalDiscoveredBy,
    required this.originalDiscoveredByName,
    required this.originalConfidence,
    this.imageBase64,
    this.latitude,
    this.longitude,
    this.status = CorrectionStatus.pending,
    this.upvotes = 0,
    this.downvotes = 0,
    this.voterIds = const [],
    DateTime? submittedAt,
    this.verifiedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  /// Check if user has already voted on this correction
  bool hasVoted(String userId) => voterIds.contains(userId);

  /// Check if correction should be approved
  bool get shouldApprove => upvotes >= upvotesRequired;

  /// Check if correction should be rejected
  bool get shouldReject => downvotes >= downvotesRequired;

  PlantCorrection copyWith({
    String? id,
    String? originalTreasureId,
    String? originalPlantName,
    String? correctedPlantName,
    String? correctedBy,
    String? correctedByName,
    String? originalDiscoveredBy,
    String? originalDiscoveredByName,
    double? originalConfidence,
    String? imageBase64,
    double? latitude,
    double? longitude,
    CorrectionStatus? status,
    int? upvotes,
    int? downvotes,
    List<String>? voterIds,
    DateTime? submittedAt,
    DateTime? verifiedAt,
  }) {
    return PlantCorrection(
      id: id ?? this.id,
      originalTreasureId: originalTreasureId ?? this.originalTreasureId,
      originalPlantName: originalPlantName ?? this.originalPlantName,
      correctedPlantName: correctedPlantName ?? this.correctedPlantName,
      correctedBy: correctedBy ?? this.correctedBy,
      correctedByName: correctedByName ?? this.correctedByName,
      originalDiscoveredBy: originalDiscoveredBy ?? this.originalDiscoveredBy,
      originalDiscoveredByName: originalDiscoveredByName ?? this.originalDiscoveredByName,
      originalConfidence: originalConfidence ?? this.originalConfidence,
      imageBase64: imageBase64 ?? this.imageBase64,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      voterIds: voterIds ?? this.voterIds,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'originalTreasureId': originalTreasureId,
      'originalPlantName': originalPlantName,
      'correctedPlantName': correctedPlantName,
      'correctedBy': correctedBy,
      'correctedByName': correctedByName,
      'originalDiscoveredBy': originalDiscoveredBy,
      'originalDiscoveredByName': originalDiscoveredByName,
      'originalConfidence': originalConfidence,
      'imageBase64': imageBase64,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'voterIds': voterIds,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
    };
  }

  factory PlantCorrection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlantCorrection(
      id: doc.id,
      originalTreasureId: data['originalTreasureId'] ?? '',
      originalPlantName: data['originalPlantName'] ?? '',
      correctedPlantName: data['correctedPlantName'] ?? '',
      correctedBy: data['correctedBy'] ?? '',
      correctedByName: data['correctedByName'] ?? 'Anonymous',
      originalDiscoveredBy: data['originalDiscoveredBy'] ?? '',
      originalDiscoveredByName: data['originalDiscoveredByName'] ?? 'Unknown',
      originalConfidence: (data['originalConfidence'] ?? 0.0).toDouble(),
      imageBase64: data['imageBase64'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      status: CorrectionStatusExtension.fromString(data['status'] ?? 'pending'),
      upvotes: data['upvotes'] ?? 0,
      downvotes: data['downvotes'] ?? 0,
      voterIds: List<String>.from(data['voterIds'] ?? []),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Status of a plant correction submission
enum CorrectionStatus {
  pending,    // Awaiting community votes
  approved,   // Community approved - correction applied
  rejected,   // Community rejected - original name kept
}

extension CorrectionStatusExtension on CorrectionStatus {
  String get displayName {
    switch (this) {
      case CorrectionStatus.pending:
        return 'Pending Review';
      case CorrectionStatus.approved:
        return 'Approved';
      case CorrectionStatus.rejected:
        return 'Rejected';
    }
  }

  String get emoji {
    switch (this) {
      case CorrectionStatus.pending:
        return '⏳';
      case CorrectionStatus.approved:
        return '✅';
      case CorrectionStatus.rejected:
        return '❌';
    }
  }

  int get colorValue {
    switch (this) {
      case CorrectionStatus.pending:
        return 0xFFFF9800; // Orange
      case CorrectionStatus.approved:
        return 0xFF4CAF50; // Green
      case CorrectionStatus.rejected:
        return 0xFFF44336; // Red
    }
  }

  static CorrectionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return CorrectionStatus.approved;
      case 'rejected':
        return CorrectionStatus.rejected;
      default:
        return CorrectionStatus.pending;
    }
  }
}
