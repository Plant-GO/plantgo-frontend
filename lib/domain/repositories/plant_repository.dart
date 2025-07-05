import 'package:dartz/dartz.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/models/plant/plant_model.dart';

abstract class PlantRepository {
  Future<Either<Failure, List<PlantModel>>> getAllPlants();
  Future<Either<Failure, List<PlantModel>>> getUserPlants(String userId);
  Future<Either<Failure, PlantModel>> createPlant(PlantModel plant);
  Future<Either<Failure, PlantModel>> updatePlant(PlantModel plant);
  Future<Either<Failure, void>> deletePlant(String plantId);
  Future<Either<Failure, PlantModel>> getPlantById(String plantId);
}
