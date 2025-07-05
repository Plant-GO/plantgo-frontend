import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/domain/usecases/get_user_plants_usecase.dart';
import 'package:plantgo/presentation/blocs/my_plants/my_plants_state.dart';

@injectable
class MyPlantsCubit extends Cubit<MyPlantsState> {
  final GetUserPlantsUseCase _getUserPlantsUseCase;

  MyPlantsCubit(this._getUserPlantsUseCase) : super(MyPlantsInitial());

  Future<void> loadUserPlants(String userId) async {
    if (userId.isEmpty) {
      emit(const MyPlantsError(message: 'User not authenticated'));
      return;
    }

    emit(MyPlantsLoading());

    final result = await _getUserPlantsUseCase(userId);

    result.fold(
      (failure) => emit(MyPlantsError(message: failure.message)),
      (plants) {
        if (plants.isEmpty) {
          emit(const MyPlantsEmpty(
            message: 'No plants discovered yet. Start exploring to find your first plant!',
          ));
        } else {
          emit(MyPlantsLoaded(plants: plants, userId: userId));
        }
      },
    );
  }

  Future<void> refreshPlants(String userId) async {
    await loadUserPlants(userId);
  }

  void clearPlants() {
    emit(MyPlantsInitial());
  }
}
