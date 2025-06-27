import 'package:dartz/dartz.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/domain/entities/riddle_entity.dart';
import 'package:plantgo/domain/repositories/riddle_repository.dart';

class GetRiddleByLevelUseCase {
  final RiddleRepository repository;

  GetRiddleByLevelUseCase(this.repository);

  Future<Either<Failure, RiddleEntity>> call(int levelIndex) async {
    return await repository.getRiddleByLevel(levelIndex);
  }
}
