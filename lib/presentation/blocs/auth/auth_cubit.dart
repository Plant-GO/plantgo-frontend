import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/domain/usecases/auth_usecases.dart';
import 'package:plantgo/presentation/blocs/auth/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInWithEmailUseCase _signInWithEmailUseCase;
  final SignUpWithEmailUseCase _signUpWithEmailUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInAsGuestUseCase _signInAsGuestUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthCubit(
    this._signInWithEmailUseCase,
    this._signUpWithEmailUseCase,
    this._signInWithGoogleUseCase,
    this._signInAsGuestUseCase,
    this._signOutUseCase,
    this._getCurrentUserUseCase,
  ) : super(AuthInitial());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    
    final result = await _signInWithEmailUseCase(
      email: email,
      password: password,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    emit(AuthLoading());
    
    final result = await _signUpWithEmailUseCase(
      email: email,
      password: password,
      fullName: name,
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    
    final result = await _signInWithGoogleUseCase();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> signInAsGuest() async {
    emit(AuthLoading());
    
    final result = await _signInAsGuestUseCase();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    
    final result = await _signOutUseCase();

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    
    final result = await _getCurrentUserUseCase();
    
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  void clearAuth() {
    emit(AuthUnauthenticated());
  }
}
