import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_model.freezed.dart';
part 'character_model.g.dart';

@freezed
class CharacterModel with _$CharacterModel {
  const factory CharacterModel({
    required String id,
    required String name,
    required String assetPath,
    String? description,
    @Default(false) bool isUnlocked,
    @Default(false) bool isSelected,
  }) = _CharacterModel;

  factory CharacterModel.fromJson(Map<String, dynamic> json) =>
      _$CharacterModelFromJson(json);
}

// Predefined characters
class GameCharacters {
  static const List<CharacterModel> characters = [
    CharacterModel(
      id: 'mascot_1',
      name: 'Forest Guardian',
      assetPath: 'assets/mascot/mascots.png',
      description: 'A wise guardian of the forest',
      isUnlocked: true,
      isSelected: true,
    ),
    CharacterModel(
      id: 'mascot_2',
      name: 'Plant Explorer',
      assetPath: 'assets/mascot/mascots 2.png',
      description: 'An adventurous plant explorer',
      isUnlocked: true,
    ),
    CharacterModel(
      id: 'mascot_3',
      name: 'Nature Friend',
      assetPath: 'assets/mascot/image.png',
      description: 'A friendly nature companion',
      isUnlocked: true,
    ),
    CharacterModel(
      id: 'bird_1',
      name: 'Sky Watcher',
      assetPath: 'assets/icons/birds1.png',
      description: 'A bird that watches over the plants',
      isUnlocked: true,
    ),
    CharacterModel(
      id: 'bird_2',
      name: 'Cloud Hopper',
      assetPath: 'assets/icons/birds2.png',
      description: 'A cheerful bird companion',
      isUnlocked: true,
    ),
    CharacterModel(
      id: 'plant_icon',
      name: 'PlantGo Buddy',
      assetPath: 'assets/icons/Plantgo.png',
      description: 'The official PlantGo mascot',
      isUnlocked: true,
    ),
  ];
}
