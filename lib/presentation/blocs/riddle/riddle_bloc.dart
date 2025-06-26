import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plantgo/domain/usecases/get_riddle_by_level_usecase.dart';
import 'package:plantgo/domain/usecases/get_active_riddles_usecase.dart';
import 'package:plantgo/presentation/blocs/riddle/riddle_event.dart';
import 'package:plantgo/presentation/blocs/riddle/riddle_state.dart';

class RiddleBloc extends Bloc<RiddleEvent, RiddleState> {
  final GetRiddleByLevelUseCase getRiddleByLevelUseCase;
  final GetActiveRiddlesUseCase getActiveRiddlesUseCase;

  RiddleBloc({
    required this.getRiddleByLevelUseCase,
    required this.getActiveRiddlesUseCase,
  }) : super(const RiddleInitial()) {
    on<LoadRiddleByLevel>(_onLoadRiddleByLevel);
    on<LoadActiveRiddles>(_onLoadActiveRiddles);
    on<RefreshRiddle>(_onRefreshRiddle);
  }

  Future<void> _onLoadRiddleByLevel(
    LoadRiddleByLevel event,
    Emitter<RiddleState> emit,
  ) async {
    emit(const RiddleLoading());
    
    final result = await getRiddleByLevelUseCase(event.levelIndex);
    
    result.fold(
      (failure) => emit(RiddleError(message: failure.message)),
      (riddle) => emit(RiddleLoaded(riddle: riddle)),
    );
  }

  Future<void> _onLoadActiveRiddles(
    LoadActiveRiddles event,
    Emitter<RiddleState> emit,
  ) async {
    emit(const RiddleLoading());
    
    final result = await getActiveRiddlesUseCase();
    
    result.fold(
      (failure) => emit(RiddleError(message: failure.message)),
      (riddles) => emit(RiddlesLoaded(riddles: riddles)),
    );
  }

  Future<void> _onRefreshRiddle(
    RefreshRiddle event,
    Emitter<RiddleState> emit,
  ) async {
    if (state is RiddleLoaded) {
      final currentRiddle = (state as RiddleLoaded).riddle;
      add(LoadRiddleByLevel(levelIndex: currentRiddle.levelIndex));
    }
  }
}
