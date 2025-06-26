import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/core/usecases/usecase.dart';
import 'package:plantgo/domain/entities/user_entity.dart';
import 'package:plantgo/domain/repositories/auth_repository.dart';

@injectable
class SignInWithEmailUseCase implements UseCase<UserEntity, SignInWithEmailParams> {
  final AuthRepository repository;

  SignInWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInWithEmailParams params) async {
    return await repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInWithEmailParams extends Equatable {
  final String email;
  final String password;

  const SignInWithEmailParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
