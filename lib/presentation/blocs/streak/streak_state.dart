import 'package:equatable/equatable.dart';

class StreakData extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final List<DateTime> plantDiscoveryDates;
  final int totalPlantsDiscovered;
  final int plantsThisWeek;
  final int plantsThisMonth;
  final Map<String, int> plantTypeStats; // Plant type -> count
  final DateTime? lastDiscoveryDate;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.plantDiscoveryDates,
    required this.totalPlantsDiscovered,
    required this.plantsThisWeek,
    required this.plantsThisMonth,
    required this.plantTypeStats,
    this.lastDiscoveryDate,
  });

  @override
  List<Object?> get props => [
        currentStreak,
        longestStreak,
        plantDiscoveryDates,
        totalPlantsDiscovered,
        plantsThisWeek,
        plantsThisMonth,
        plantTypeStats,
        lastDiscoveryDate,
      ];
}

abstract class StreakState extends Equatable {
  const StreakState();

  @override
  List<Object?> get props => [];
}

class StreakInitial extends StreakState {}

class StreakLoading extends StreakState {}

class StreakLoaded extends StreakState {
  final StreakData streakData;

  const StreakLoaded({required this.streakData});

  @override
  List<Object?> get props => [streakData];
}

class StreakError extends StreakState {
  final String message;

  const StreakError({required this.message});

  @override
  List<Object?> get props => [message];
}
