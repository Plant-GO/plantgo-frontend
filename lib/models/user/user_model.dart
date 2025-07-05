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
    String? selectedCharacterId,
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,
    DateTime? joinedDate,
    DateTime? lastActive,
    @Default([]) List<String> achievements,
    @Default([]) List<String> friends,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
