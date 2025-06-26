import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/core/usecases/usecase.dart';
import 'package:plantgo/domain/entities/user_entity.dart';
import 'package:plantgo/domain/repositories/auth_repository.dart';

@injectable
class SignInWithGoogleUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  SignInWithGoogleUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.signInWithGoogle();
  }
}
