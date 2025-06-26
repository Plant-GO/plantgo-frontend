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
  // Convert from legacy Treasure model
  static PlantModel fromTreasure(Map<String, dynamic> map) {
    return PlantModel(
      id: map['id'] ?? '',
      name: map['name'] as String,
      latitude: map['lat'] as double,
      longitude: map['lng'] as double,
      imageUrl: map['imageUrl'] as String,
      imageChunks: map['imageChunks'] != null 
          ? List<String>.from(map['imageChunks']) 
          : [],
      isChunkedImage: map['isChunkedImage'] as bool? ?? false,
      createdAt: DateTime.now(),
    );
  }

  // Convert to legacy Treasure format if needed
  Map<String, dynamic> toTreasureMap() {
    return {
      'id': id,
      'name': name,
      'lat': latitude,
      'lng': longitude,
      'imageUrl': imageUrl,
      if (imageChunks?.isNotEmpty ?? false) 'imageChunks': imageChunks,
      if (isChunkedImage) 'isChunkedImage': isChunkedImage,
    };
  }
}
