import 'package:equatable/equatable.dart';
import 'package:plantgo/models/user/user_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  final Map<String, dynamic> streakData;

  const ProfileLoaded({
    required this.user,
    required this.streakData,
  });

  @override
  List<Object?> get props => [user, streakData];
}

class ProfileUpdated extends ProfileState {
  final UserModel user;

  const ProfileUpdated({required this.user});

  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
