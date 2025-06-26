import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/models/user/user_model.dart';
import 'package:plantgo/presentation/blocs/profile/profile_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  final ApiService _apiService;

  ProfileCubit(this._apiService) : super(ProfileInitial());

  Future<void> loadProfile() async {
    try {
      emit(ProfileLoading());
      
      // Mock user data for now - replace with API call later
      final mockUser = UserModel(
        id: 'user_1',
        name: 'Dikshit Bhatta',
        email: 'dikshit@example.com',
        coursesCompleted: 0,
        following: 0,
        followers: 0,
        currentStreak: 1,
        longestStreak: 5,
        joinedDate: DateTime(2024, 10, 1),
        lastActive: DateTime.now(),
      );

      // Mock streak data
      final streakData = {
        'currentStreak': 1,
        'longestStreak': 5,
        'streakCalendar': _generateMockStreakCalendar(),
        'goal': 14,
        'progress': 1 / 14,
      };

      emit(ProfileLoaded(user: mockUser, streakData: streakData));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded) {
        emit(ProfileLoading());

        // Create updated user
        final updatedUser = UserModel(
          id: currentState.user.id,
          name: name ?? currentState.user.name,
          email: email ?? currentState.user.email,
          avatarUrl: avatarUrl ?? currentState.user.avatarUrl,
          coursesCompleted: currentState.user.coursesCompleted,
          following: currentState.user.following,
          followers: currentState.user.followers,
          currentStreak: currentState.user.currentStreak,
          longestStreak: currentState.user.longestStreak,
          joinedDate: currentState.user.joinedDate,
          lastActive: DateTime.now(),
          achievements: currentState.user.achievements,
        );

        emit(ProfileLoaded(
          user: updatedUser,
          streakData: currentState.streakData,
        ));

        emit(ProfileUpdated(user: updatedUser));

        // TODO: Call API to update profile
        // await _apiService.updateUserProfile(user: updatedUser);
      }
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> updateStreak() async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded) {
        final currentStreak = currentState.user.currentStreak + 1;
        final longestStreak = currentStreak > currentState.user.longestStreak
            ? currentStreak
            : currentState.user.longestStreak;

        final updatedUser = UserModel(
          id: currentState.user.id,
          name: currentState.user.name,
          email: currentState.user.email,
          avatarUrl: currentState.user.avatarUrl,
          coursesCompleted: currentState.user.coursesCompleted,
          following: currentState.user.following,
          followers: currentState.user.followers,
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          joinedDate: currentState.user.joinedDate,
          lastActive: DateTime.now(),
          achievements: currentState.user.achievements,
        );

        final updatedStreakData = Map<String, dynamic>.from(currentState.streakData);
        updatedStreakData['currentStreak'] = currentStreak;
        updatedStreakData['longestStreak'] = longestStreak;
        updatedStreakData['progress'] = currentStreak / 14;

        emit(ProfileLoaded(
          user: updatedUser,
          streakData: updatedStreakData,
        ));

        // TODO: Call API to update streak
        // await _apiService.updateStreak();
      }
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Map<String, dynamic> _generateMockStreakCalendar() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    final calendar = <int, bool>{};
    for (int i = 1; i <= daysInMonth; i++) {
      // Mock some completed days
      calendar[i] = i <= now.day && i % 3 == 0;
    }
    
    // Mark today as completed
    calendar[now.day] = true;
    
    return {
      'month': '${_getMonthName(now.month)} ${now.year}',
      'days': calendar,
      'highlighted': now.day,
    };
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void clearProfile() {
    emit(ProfileInitial());
  }
}
