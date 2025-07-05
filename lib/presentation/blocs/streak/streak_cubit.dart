import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/domain/usecases/get_user_plants_usecase.dart';
import 'package:plantgo/presentation/blocs/streak/streak_state.dart';

@injectable
class StreakCubit extends Cubit<StreakState> {
  final GetUserPlantsUseCase _getUserPlantsUseCase;

  StreakCubit(this._getUserPlantsUseCase) : super(StreakInitial());

  Future<void> loadStreakData(String userId) async {
    emit(StreakLoading());
    
    try {
      final result = await _getUserPlantsUseCase(userId);
      
      result.fold(
        (failure) => emit(StreakError(message: failure.message)),
        (plants) {
          // Calculate streak data from plant discovery dates
          final discoveryDates = plants
              .map((plant) => plant.createdAt)
              .toList()
            ..sort();

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          // Calculate current streak
          int currentStreak = 0;
          DateTime checkDate = today;
          
          for (int i = discoveryDates.length - 1; i >= 0; i--) {
            final discoveryDate = DateTime(
              discoveryDates[i].year,
              discoveryDates[i].month,
              discoveryDates[i].day,
            );
            
            if (discoveryDate == checkDate) {
              currentStreak++;
              checkDate = checkDate.subtract(const Duration(days: 1));
            } else if (discoveryDate.isBefore(checkDate)) {
              break;
            }
          }
          
          // Calculate longest streak
          int longestStreak = 0;
          int tempStreak = 0;
          DateTime? lastDate;
          
          for (final date in discoveryDates) {
            final discoveryDate = DateTime(date.year, date.month, date.day);
            
            if (lastDate == null || 
                discoveryDate.difference(lastDate).inDays == 1) {
              tempStreak++;
              longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
            } else {
              tempStreak = 1;
            }
            lastDate = discoveryDate;
          }
          
          // Calculate plants this week/month
          final weekAgo = today.subtract(const Duration(days: 7));
          final monthAgo = DateTime(today.year, today.month - 1, today.day);
          
          final plantsThisWeek = plants
              .where((plant) => plant.createdAt.isAfter(weekAgo))
              .length;
              
          final plantsThisMonth = plants
              .where((plant) => plant.createdAt.isAfter(monthAgo))
              .length;
          
          // Calculate plant type statistics (using species as type)
          final plantTypeStats = <String, int>{};
          for (final plant in plants) {
            final type = plant.species ?? plant.family ?? 'Unknown';
            plantTypeStats[type] = (plantTypeStats[type] ?? 0) + 1;
          }
          
          final streakData = StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            plantDiscoveryDates: discoveryDates,
            totalPlantsDiscovered: plants.length,
            plantsThisWeek: plantsThisWeek,
            plantsThisMonth: plantsThisMonth,
            plantTypeStats: plantTypeStats,
            lastDiscoveryDate: discoveryDates.isNotEmpty ? discoveryDates.last : null,
          );
          
          emit(StreakLoaded(streakData: streakData));
        },
      );
    } catch (e) {
      emit(StreakError(message: 'Failed to load streak data: ${e.toString()}'));
    }
  }
}
