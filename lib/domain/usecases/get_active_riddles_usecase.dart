import 'package:dartz/dartz.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/domain/entities/riddle_entity.dart';
import 'package:plantgo/domain/repositories/riddle_repository.dart';

class GetActiveRiddlesUseCase {
  final RiddleRepository repository;

  GetActiveRiddlesUseCase(this.repository);

  Future<Either<Failure, List<RiddleEntity>>> call() async {
    return await repository.getActiveRiddles();
  }
}
