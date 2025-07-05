import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/core/usecases/usecase.dart';
import 'package:plantgo/models/plant/plant_model.dart';
import 'package:plantgo/domain/repositories/plant_repository.dart';

@injectable
class GetUserPlantsUseCase implements UseCase<List<PlantModel>, String> {
  final PlantRepository repository;

  GetUserPlantsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PlantModel>>> call(String userId) async {
    return await repository.getUserPlants(userId);
  }
}
