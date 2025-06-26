class RiddleEntity {
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

  const RiddleEntity({
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiddleEntity &&
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
    return 'RiddleEntity(id: $id, levelIndex: $levelIndex, riddleText: $riddleText, plantScientificName: $plantScientificName, plantCommonName: $plantCommonName, hint: $hint, imageUrl: $imageUrl, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
