import 'package:plantgo/domain/entities/riddle_entity.dart';

class RiddleModel {
  final String id;
  final int levelIndex;
  final String riddleText;
  final String plantScientificName;
  final String plantCommonName;
  final String? hint;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RiddleModel({
    required this.id,
    required this.levelIndex,
    required this.riddleText,
    required this.plantScientificName,
    required this.plantCommonName,
    this.hint,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert JSON from API to RiddleModel
  factory RiddleModel.fromJson(Map<String, dynamic> json) {
    return RiddleModel(
      id: json['id'] ?? '',
      levelIndex: json['levelIndex'] ?? 0,
      riddleText: json['riddleText'] ?? '',
      plantScientificName: json['plantScientificName'] ?? '',
      plantCommonName: json['plantCommonName'] ?? '',
      hint: json['hint'],
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert Map from Firestore to RiddleModel
  factory RiddleModel.fromMap(Map<String, dynamic> map) {
    return RiddleModel(
      id: map['id'] ?? '',
      levelIndex: map['levelIndex'] ?? 0,
      riddleText: map['riddleText'] ?? '',
      plantScientificName: map['plantScientificName'] ?? '',
      plantCommonName: map['plantCommonName'] ?? '',
      hint: map['hint'],
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert RiddleModel to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'levelIndex': levelIndex,
      'riddleText': riddleText,
      'plantScientificName': plantScientificName,
      'plantCommonName': plantCommonName,
      'hint': hint,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert RiddleModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'levelIndex': levelIndex,
      'riddleText': riddleText,
      'plantScientificName': plantScientificName,
      'plantCommonName': plantCommonName,
      'hint': hint,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert RiddleModel to RiddleEntity
  RiddleEntity toEntity() {
    return RiddleEntity(
      id: id,
      levelIndex: levelIndex,
      riddleText: riddleText,
      plantScientificName: plantScientificName,
      plantCommonName: plantCommonName,
      hint: hint,
      imageUrl: imageUrl,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Create RiddleModel from RiddleEntity
  factory RiddleModel.fromEntity(RiddleEntity entity) {
    return RiddleModel(
      id: entity.id,
      levelIndex: entity.levelIndex,
      riddleText: entity.riddleText,
      plantScientificName: entity.plantScientificName,
      plantCommonName: entity.plantCommonName,
      hint: entity.hint,
      imageUrl: entity.imageUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiddleModel &&
        other.id == id &&
        other.levelIndex == levelIndex &&
        other.riddleText == riddleText &&
        other.plantScientificName == plantScientificName &&
        other.plantCommonName == plantCommonName &&
        other.hint == hint &&
        other.imageUrl == imageUrl &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        levelIndex.hashCode ^
        riddleText.hashCode ^
        plantScientificName.hashCode ^
        plantCommonName.hashCode ^
        hint.hashCode ^
        imageUrl.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'RiddleModel(id: $id, levelIndex: $levelIndex, riddleText: $riddleText, plantScientificName: $plantScientificName, plantCommonName: $plantCommonName, hint: $hint, imageUrl: $imageUrl, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
