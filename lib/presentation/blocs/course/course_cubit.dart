import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/models/course/course_model.dart';
import 'package:plantgo/presentation/blocs/course/course_state.dart';

@injectable
class CourseCubit extends Cubit<CourseState> {
  final ApiService _apiService;

  CourseCubit(this._apiService) : super(CourseInitial());

  Future<void> loadCourse({String? courseId}) async {
    try {
      emit(CourseLoading());
      
      // For now, we'll create a mock course since we don't have backend yet
      // In the future, this will fetch from the API
      final mockCourse = CourseModel(
        id: courseId ?? 'course_1',
        title: 'Plant Discovery Journey',
        description: 'Learn to identify and discover plants around you',
        levels: [
          const LevelModel(
            id: 'level_0',
            title: 'Getting Started',
            imageUrl: 'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic.png',
            levelIndex: 0,
            isCompleted: true,
          ),
          const LevelModel(
            id: 'level_1',
            title: 'Forest Explorer',
            imageUrl: 'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic (1).png',
            levelIndex: 1,
            isCompleted: false,
          ),
          const LevelModel(
            id: 'level_2',
            title: 'Plant Detective',
            imageUrl: 'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic (2).png',
            levelIndex: 2,
            isCompleted: false,
            isLocked: false,
          ),
          const LevelModel(
            id: 'level_3',
            title: 'Nature Master',
            imageUrl: 'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic (3).png',
            levelIndex: 3,
            isCompleted: false,
            isLocked: true,
          ),
        ],
        completedLevels: 1,
      );

      emit(CourseLoaded(course: mockCourse, currentLevel: 2));
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> completeLevel(int levelIndex) async {
    try {
      final currentState = state;
      if (currentState is CourseLoaded) {
        // Update the level completion status
        final updatedLevels = currentState.course.levels.map((level) {
          if (level.levelIndex == levelIndex) {
            return level.copyWith(isCompleted: true);
          }
          // Unlock next level
          if (level.levelIndex == levelIndex + 1) {
            return level.copyWith(isLocked: false);
          }
          return level;
        }).toList();

        final updatedCourse = currentState.course.copyWith(
          levels: updatedLevels,
          completedLevels: currentState.course.completedLevels + 1,
        );

        emit(CourseLoaded(
          course: updatedCourse,
          currentLevel: levelIndex + 1,
        ));

        // Emit completion event
        emit(CourseLevelCompleted(completedLevel: levelIndex));
        
        // Return to loaded state
        emit(CourseLoaded(
          course: updatedCourse,
          currentLevel: levelIndex + 1,
        ));

        // TODO: Update progress on backend
        // await _apiService.updateCourseProgress(
        //   courseId: updatedCourse.id,
        //   levelIndex: levelIndex,
        //   completed: true,
        // );
      }
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  Future<void> selectLevel(int levelIndex) async {
    try {
      final currentState = state;
      if (currentState is CourseLoaded) {
        final level = currentState.course.levels.firstWhere(
          (l) => l.levelIndex == levelIndex,
        );
        
        if (!level.isLocked) {
          emit(CourseLoaded(
            course: currentState.course,
            currentLevel: levelIndex,
          ));
        }
      }
    } catch (e) {
      emit(CourseError(message: e.toString()));
    }
  }

  void resetCourse() {
    emit(CourseInitial());
  }
}
