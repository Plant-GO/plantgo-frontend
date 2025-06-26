import 'package:plantgo/domain/entities/riddle_entity.dart';

class MockRiddleData {
  static List<RiddleEntity> get mockRiddles => [
    RiddleEntity(
      id: 'riddle_1',
      levelIndex: 0,
      riddleText: "I'm a tropical beauty with split leaves that resemble Swiss cheese. My large, glossy foliage can grow quite massive indoors. What am I?",
      plantScientificName: 'Monstera deliciosa',
      plantCommonName: 'Swiss Cheese Plant',
      hint: 'Look for the characteristic holes and splits in my leaves!',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    RiddleEntity(
      id: 'riddle_2',
      levelIndex: 1,
      riddleText: "I'm known for my elegant white flowers that look like flags of surrender. I can purify your air and I love humidity. What am I?",
      plantScientificName: 'Spathiphyllum wallisii',
      plantCommonName: 'Peace Lily',
      hint: 'My white flowers are actually modified leaves called spathes!',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    RiddleEntity(
      id: 'riddle_3',
      levelIndex: 2,
      riddleText: "I'm virtually indestructible with thick, upright leaves that have yellow edges. I can survive neglect and low light. What am I?",
      plantScientificName: 'Sansevieria trifasciata',
      plantCommonName: 'Snake Plant',
      hint: "I'm also called Mother-in-Law's Tongue for my sharp appearance!",
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    RiddleEntity(
      id: 'riddle_4',
      levelIndex: 3,
      riddleText: "I have large, violin-shaped leaves and I'm quite finicky about my environment. I prefer bright, indirect light and consistent care. What am I?",
      plantScientificName: 'Ficus lyrata',
      plantCommonName: 'Fiddle Leaf Fig',
      hint: 'My leaves really do look like the musical instrument I\'m named after!',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static RiddleEntity? getRiddleByLevel(int levelIndex) {
    try {
      return mockRiddles.firstWhere((riddle) => riddle.levelIndex == levelIndex);
    } catch (e) {
      return null;
    }
  }

  static List<RiddleEntity> getActiveRiddles() {
    return mockRiddles.where((riddle) => riddle.isActive).toList();
  }
}
