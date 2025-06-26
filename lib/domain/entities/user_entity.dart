import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isEmailVerified,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        profileImageUrl,
        createdAt,
        updatedAt,
        isEmailVerified,
      ];

  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
