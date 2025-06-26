import 'package:equatable/equatable.dart';

abstract class StartGameState extends Equatable {
  const StartGameState();

  @override
  List<Object?> get props => [];
}

class StartGameInitial extends StartGameState {}

class StartGameLoading extends StartGameState {}

class StartGameLoaded extends StartGameState {
  final int coins;
  final int streaks;
  final int experience;

  const StartGameLoaded({
    required this.coins,
    required this.streaks,
    required this.experience,
  });

  @override
  List<Object?> get props => [coins, streaks, experience];
}

class StartGameError extends StartGameState {
  final String message;

  const StartGameError(this.message);

  @override
  List<Object?> get props => [message];
}
