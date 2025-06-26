import 'package:dartz/dartz.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/core/error/failures.dart';
import 'package:plantgo/data/models/user_model.dart';
import 'package:plantgo/domain/entities/user_entity.dart';
import 'package:plantgo/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;

  AuthRepositoryImpl(this._apiService);

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data!['user'];
        final userModel = UserModel.fromMap(userData);
        return Right(userModel.toEntity());
      } else {
        return Left(ServerFailure('Login failed'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        name: fullName,
      );

      if (response.statusCode == 201 && response.data != null) {
        final userData = response.data!['user'];
        final userModel = UserModel.fromMap(userData);
        return Right(userModel.toEntity());
      } else {
        return Left(ServerFailure('Registration failed'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      // TODO: Implement Google sign-in
      // For now, simulate a successful Google login
      final userModel = UserModel(
        id: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'google.user@gmail.com',
        fullName: 'Google User',
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: true,
      );
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInAsGuest() async {
    try {
      // Create a guest user
      final userModel = UserModel(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        email: 'guest@plantgo.com',
        fullName: 'Guest User',
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: false,
      );
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _apiService.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final response = await _apiService.getUserProfile();
      
      if (response.statusCode == 200 && response.data != null) {
        final userModel = UserModel.fromMap(response.data!);
        return Right(userModel.toEntity());
      } else {
        return const Right(null);
      }
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      // TODO: Implement password reset
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail() async {
    try {
      // TODO: Implement email verification
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, UserEntity?>> get authStateChanges {
    // TODO: Implement auth state changes stream
    // This would typically listen to authentication state changes
    return Stream.value(const Right(null));
  }
}
