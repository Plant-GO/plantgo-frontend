abstract class RiddleEvent {
  const RiddleEvent();
}

class LoadRiddleByLevel extends RiddleEvent {
  final int levelIndex;
  
  const LoadRiddleByLevel({required this.levelIndex});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadRiddleByLevel && other.levelIndex == levelIndex;
  }

  @override
  int get hashCode => levelIndex.hashCode;
}

class LoadActiveRiddles extends RiddleEvent {
  const LoadActiveRiddles();
}

class RefreshRiddle extends RiddleEvent {
  const RefreshRiddle();
}
