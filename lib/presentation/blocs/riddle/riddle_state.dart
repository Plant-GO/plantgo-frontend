import 'package:plantgo/domain/entities/riddle_entity.dart';

abstract class RiddleState {
  const RiddleState();
}

class RiddleInitial extends RiddleState {
  const RiddleInitial();
}

class RiddleLoading extends RiddleState {
  const RiddleLoading();
}

class RiddleLoaded extends RiddleState {
  final RiddleEntity riddle;
  
  const RiddleLoaded({required this.riddle});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiddleLoaded && other.riddle == riddle;
  }

  @override
  int get hashCode => riddle.hashCode;
}

class RiddleError extends RiddleState {
  final String message;
  
  const RiddleError({required this.message});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiddleError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class RiddlesLoaded extends RiddleState {
  final List<RiddleEntity> riddles;
  
  const RiddlesLoaded({required this.riddles});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RiddlesLoaded && 
           other.riddles.length == riddles.length &&
           other.riddles.every((riddle) => riddles.contains(riddle));
  }

  @override
  int get hashCode => riddles.hashCode;
}
