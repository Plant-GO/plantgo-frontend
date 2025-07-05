// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterModelImpl _$$CharacterModelImplFromJson(Map<String, dynamic> json) =>
    _$CharacterModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      assetPath: json['assetPath'] as String,
      description: json['description'] as String?,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isSelected: json['isSelected'] as bool? ?? false,
    );

Map<String, dynamic> _$$CharacterModelImplToJson(
        _$CharacterModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'assetPath': instance.assetPath,
      'description': instance.description,
      'isUnlocked': instance.isUnlocked,
      'isSelected': instance.isSelected,
    };
