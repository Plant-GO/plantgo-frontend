import 'package:dartz/dartz.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/domain/entities/riddle_entity.dart';

abstract class RiddleRepository {
  Future<Either<Failure, List<RiddleEntity>>> getAllRiddles();
  Future<Either<Failure, RiddleEntity>> getRiddleByLevel(int levelIndex);
  Future<Either<Failure, List<RiddleEntity>>> getActiveRiddles();
  Future<Either<Failure, RiddleEntity>> createRiddle(RiddleEntity riddle);
  Future<Either<Failure, RiddleEntity>> updateRiddle(RiddleEntity riddle);
  Future<Either<Failure, void>> deleteRiddle(String riddleId);
}
