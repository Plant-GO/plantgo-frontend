import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:plantgo/core/services/audio_service.dart';
import 'package:plantgo/presentation/blocs/settings/settings_state.dart';

@injectable
class SettingsCubit extends Cubit<SettingsState> {
  final AudioService _audioService;

  SettingsCubit(this._audioService) : super(SettingsInitial());

  void loadSettings() {
    emit(SettingsLoading());
    try {
      final isSoundEnabled = _audioService.isSoundEnabled;
      emit(SettingsLoaded(isSoundEnabled: isSoundEnabled));
    } catch (e) {
      emit(SettingsError(message: 'Failed to load settings: ${e.toString()}'));
    }
  }

  void toggleSound(bool isEnabled) {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      try {
        _audioService.setSoundEnabled(isEnabled);
        emit(SettingsLoaded(isSoundEnabled: isEnabled));
      } catch (e) {
        emit(SettingsError(message: 'Failed to update sound setting: ${e.toString()}'));
        // Revert to previous state if error occurs
        emit(currentState);
      }
    }
  }
}
