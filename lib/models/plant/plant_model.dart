import 'package:freezed_annotation/freezed_annotation.dart';

part 'plant_model.freezed.dart';
part 'plant_model.g.dart';

@freezed
class PlantModel with _$PlantModel {
  const factory PlantModel({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required String imageUrl,
    @Default([]) List<String>? imageChunks,
    @Default(false) bool isChunkedImage,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? description,
    String? species,
    String? family,
    @Default([]) List<String> tags,
    String? userId,
  }) = _PlantModel;

  factory PlantModel.fromJson(Map<String, dynamic> json) =>
      _$PlantModelFromJson(json);
}

extension PlantModelX on PlantModel {
  // Convert from Firestore document to PlantModel
  static PlantModel fromTreasure(Map<String, dynamic> map) {
    return PlantModel(
      id: map['id'] ?? '',
      name: map['name'] as String? ?? '',
      latitude: map['lat'] as double? ?? 0.0,
      longitude: map['lng'] as double? ?? 0.0,
      imageUrl: map['imageUrl'] as String? ?? '',
      imageChunks: map['imageChunks'] != null 
          ? List<String>.from(map['imageChunks']) 
          : [],
      isChunkedImage: map['isChunkedImage'] as bool? ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      description: map['description'] as String?,
      species: map['species'] as String?,
      family: map['family'] as String?,
      tags: map['tags'] != null 
          ? List<String>.from(map['tags']) 
          : [],
      userId: map['userId'] as String?,
    );
  }

  // Convert to Firestore format with all fields
  Map<String, dynamic> toTreasureMap() {
    return {
      'name': name,
      'lat': latitude,
      'lng': longitude,
      'imageUrl': imageUrl,
      'imageChunks': imageChunks ?? [],
      'isChunkedImage': isChunkedImage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'description': description,
      'species': species,
      'family': family,
      'tags': tags,
      'userId': userId,
    };
  }
}
