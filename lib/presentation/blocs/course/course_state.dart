import 'package:equatable/equatable.dart';
import 'package:plantgo/models/course/course_model.dart';

abstract class CourseState extends Equatable {
  const CourseState();

  @override
  List<Object?> get props => [];
}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CourseLoaded extends CourseState {
  final CourseModel course;
  final int currentLevel;

  const CourseLoaded({
    required this.course,
    required this.currentLevel,
  });

  @override
  List<Object?> get props => [course, currentLevel];
}

class CourseLevelCompleted extends CourseState {
  final int completedLevel;

  const CourseLevelCompleted({required this.completedLevel});

  @override
  List<Object?> get props => [completedLevel];
}

class CourseError extends CourseState {
  final String message;

  const CourseError({required this.message});

  @override
  List<Object?> get props => [message];
}
