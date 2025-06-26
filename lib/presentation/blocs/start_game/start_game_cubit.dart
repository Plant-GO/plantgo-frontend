import 'package:flutter_bloc/flutter_bloc.dart';
import 'start_game_state.dart';

class StartGameCubit extends Cubit<StartGameState> {
  StartGameCubit() : super(StartGameInitial());

  Future<void> loadStartGameData() async {
    emit(StartGameLoading());
    
    try {
      // Simulate loading user data
      await Future.delayed(const Duration(milliseconds: 500));
      
      // For now, return mock data
      // In a real app, this would come from your repository/API
      emit(const StartGameLoaded(
        coins: 500,
        streaks: 5,
        experience: 1250,
      ));
    } catch (e) {
      emit(StartGameError('Failed to load game data: ${e.toString()}'));
    }
  }

  void startGame() {
    // Handle start game logic
    // This could navigate to the main screen or course screen
  }

  void openLeaderboard() {
    // Handle leaderboard logic
    // This could navigate to leaderboard screen
  }
}
