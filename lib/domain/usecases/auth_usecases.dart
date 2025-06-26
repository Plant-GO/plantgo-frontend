import 'package:dartz/dartz.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/domain/entities/user_entity.dart';
import 'package:plantgo/domain/repositories/auth_repository.dart';

class SignInWithEmailUseCase {
  final AuthRepository _authRepository;

  SignInWithEmailUseCase(this._authRepository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) async {
    return await _authRepository.signInWithEmail(
      email: email,
      password: password,
    );
  }
}

class SignUpWithEmailUseCase {
  final AuthRepository _authRepository;

  SignUpWithEmailUseCase(this._authRepository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _authRepository.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
    );
  }
}

class SignInWithGoogleUseCase {
  final AuthRepository _authRepository;

  SignInWithGoogleUseCase(this._authRepository);

  Future<Either<Failure, UserEntity>> call() async {
    return await _authRepository.signInWithGoogle();
  }
}

class SignInAsGuestUseCase {
  final AuthRepository _authRepository;

  SignInAsGuestUseCase(this._authRepository);

  Future<Either<Failure, UserEntity>> call() async {
    return await _authRepository.signInAsGuest();
  }
}

class SignOutUseCase {
  final AuthRepository _authRepository;

  SignOutUseCase(this._authRepository);

  Future<Either<Failure, void>> call() async {
    return await _authRepository.signOut();
  }
}

class GetCurrentUserUseCase {
  final AuthRepository _authRepository;

  GetCurrentUserUseCase(this._authRepository);

  Future<Either<Failure, UserEntity?>> call() async {
    return await _authRepository.getCurrentUser();
  }
}

class SendPasswordResetEmailUseCase {
  final AuthRepository _authRepository;

  SendPasswordResetEmailUseCase(this._authRepository);

  Future<Either<Failure, void>> call(String email) async {
    return await _authRepository.sendPasswordResetEmail(email);
  }
}
