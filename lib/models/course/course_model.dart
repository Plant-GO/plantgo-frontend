import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_model.freezed.dart';
part 'course_model.g.dart';

@freezed
class CourseModel with _$CourseModel {
  const factory CourseModel({
    required String id,
    required String title,
    required String description,
    @Default([]) List<LevelModel> levels,
    @Default(0) int completedLevels,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CourseModel;

  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModelFromJson(json);
}

@freezed
class LevelModel with _$LevelModel {
  const factory LevelModel({
    required String id,
    required String title,
    required String imageUrl,
    String? description,
    @Default(false) bool isCompleted,
    @Default(false) bool isLocked,
    int? levelIndex,
  }) = _LevelModel;

  factory LevelModel.fromJson(Map<String, dynamic> json) =>
      _$LevelModelFromJson(json);
}
