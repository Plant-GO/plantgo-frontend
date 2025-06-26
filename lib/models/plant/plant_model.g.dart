// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlantModelImpl _$$PlantModelImplFromJson(Map<String, dynamic> json) =>
    _$PlantModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      imageChunks: (json['imageChunks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isChunkedImage: json['isChunkedImage'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      description: json['description'] as String?,
      species: json['species'] as String?,
      family: json['family'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      userId: json['userId'] as String?,
    );

Map<String, dynamic> _$$PlantModelImplToJson(_$PlantModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'imageUrl': instance.imageUrl,
      'imageChunks': instance.imageChunks,
      'isChunkedImage': instance.isChunkedImage,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'description': instance.description,
      'species': instance.species,
      'family': instance.family,
      'tags': instance.tags,
      'userId': instance.userId,
    };
