import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
    @Default(0) int coursesCompleted,
    @Default(0) int following,
    @Default(0) int followers,
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    DateTime? joinedDate,
    DateTime? lastActive,
    @Default([]) List<String> achievements,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
