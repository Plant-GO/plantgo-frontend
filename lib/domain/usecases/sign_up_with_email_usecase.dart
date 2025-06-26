import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/core/usecases/usecase.dart';
import 'package:plantgo/domain/entities/user_entity.dart';
import 'package:plantgo/domain/repositories/auth_repository.dart';

@injectable
class SignUpWithEmailUseCase implements UseCase<UserEntity, SignUpWithEmailParams> {
  final AuthRepository repository;

  SignUpWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpWithEmailParams params) async {
    return await repository.signUpWithEmail(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
    );
  }
}

class SignUpWithEmailParams extends Equatable {
  final String email;
  final String password;
  final String fullName;

  const SignUpWithEmailParams({
    required this.email,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object> get props => [email, password, fullName];
}
