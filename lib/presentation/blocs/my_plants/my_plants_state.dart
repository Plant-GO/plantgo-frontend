import 'package:equatable/equatable.dart';
import 'package:plantgo/models/plant/plant_model.dart';

abstract class MyPlantsState extends Equatable {
  const MyPlantsState();

  @override
  List<Object?> get props => [];
}

class MyPlantsInitial extends MyPlantsState {}

class MyPlantsLoading extends MyPlantsState {}

class MyPlantsLoaded extends MyPlantsState {
  final List<PlantModel> plants;
  final String userId;

  const MyPlantsLoaded({
    required this.plants,
    required this.userId,
  });

  @override
  List<Object?> get props => [plants, userId];
}

class MyPlantsEmpty extends MyPlantsState {
  final String message;

  const MyPlantsEmpty({required this.message});

  @override
  List<Object?> get props => [message];
}

class MyPlantsError extends MyPlantsState {
  final String message;

  const MyPlantsError({required this.message});

  @override
  List<Object?> get props => [message];
}
