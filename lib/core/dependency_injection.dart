import 'package:get_it/get_it.dart';
import 'package:plantgo/api/api_service.dart';
import 'package:plantgo/api/http_manager.dart';
import 'package:plantgo/presentation/blocs/auth/auth_cubit.dart';
import 'package:plantgo/presentation/blocs/course/course_cubit.dart';
import 'package:plantgo/presentation/blocs/map/map_cubit.dart';
import 'package:plantgo/presentation/blocs/notifications/notifications_cubit.dart';
import 'package:plantgo/presentation/blocs/profile/profile_cubit.dart';
import 'package:plantgo/presentation/blocs/start_game/start_game_cubit.dart';
import 'package:plantgo/presentation/blocs/scanner/scanner_cubit.dart';
import 'package:plantgo/presentation/blocs/riddle/riddle_bloc.dart';
import 'package:plantgo/core/services/location_service.dart';
import 'package:plantgo/core/services/image_service.dart';
import 'package:plantgo/domain/repositories/auth_repository.dart';
import 'package:plantgo/domain/repositories/riddle_repository.dart';
import 'package:plantgo/domain/usecases/auth_usecases.dart';
import 'package:plantgo/domain/usecases/get_riddle_by_level_usecase.dart';
import 'package:plantgo/domain/usecases/get_active_riddles_usecase.dart';
import 'package:plantgo/data/repositories/auth_repository_impl.dart';
import 'package:plantgo/data/repositories/riddle_repository_impl.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Services
  getIt.registerLazySingleton<HttpManager>(() => HttpManager());
  getIt.registerLazySingleton<LocationService>(() => LocationService());
  getIt.registerLazySingleton<ImageService>(() => ImageService());
  
  // API Services
  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt<HttpManager>()));
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt<ApiService>()));
  getIt.registerLazySingleton<RiddleRepository>(() => RiddleRepositoryImpl(getIt<ApiService>()));
  
  // Use Cases
  getIt.registerLazySingleton<SignInWithEmailUseCase>(() => SignInWithEmailUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<SignUpWithEmailUseCase>(() => SignUpWithEmailUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<SignInWithGoogleUseCase>(() => SignInWithGoogleUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<SignInAsGuestUseCase>(() => SignInAsGuestUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<GetCurrentUserUseCase>(() => GetCurrentUserUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<GetRiddleByLevelUseCase>(() => GetRiddleByLevelUseCase(getIt<RiddleRepository>()));
  getIt.registerLazySingleton<GetActiveRiddlesUseCase>(() => GetActiveRiddlesUseCase(getIt<RiddleRepository>()));
  
  // BLoCs/Cubits
  getIt.registerFactory<AuthCubit>(() => AuthCubit(
    getIt<SignInWithEmailUseCase>(),
    getIt<SignUpWithEmailUseCase>(),
    getIt<SignInWithGoogleUseCase>(),
    getIt<SignInAsGuestUseCase>(),
    getIt<SignOutUseCase>(),
    getIt<GetCurrentUserUseCase>(),
  ));
  getIt.registerFactory<ProfileCubit>(() => ProfileCubit(getIt<ApiService>()));
  getIt.registerFactory<CourseCubit>(() => CourseCubit(getIt<ApiService>()));
  getIt.registerFactory<StartGameCubit>(() => StartGameCubit());
  getIt.registerFactory<MapCubit>(() => MapCubit(
    getIt<ApiService>(),
    getIt<LocationService>(),
    getIt<ImageService>(),
  ));
  getIt.registerFactory<NotificationsCubit>(() => NotificationsCubit(getIt<ApiService>()));
  getIt.registerFactory<ScannerCubit>(() => ScannerCubit(getIt<ApiService>()));
  getIt.registerFactory<RiddleBloc>(() => RiddleBloc(
    getRiddleByLevelUseCase: getIt<GetRiddleByLevelUseCase>(),
    getActiveRiddlesUseCase: getIt<GetActiveRiddlesUseCase>(),
  ));
}
