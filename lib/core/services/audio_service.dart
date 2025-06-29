import 'package:audioplayers/audioplayers.dart';
import 'package:plantgo/core/constants/app_audio.dart';

/// Singleton service to manage background audio
class AudioService {
  AudioService._internal() {
    // Debug: listen to player state changes and completion
    _player.onPlayerStateChanged.listen((state) => print('AudioService: player state -> $state'));
    _player.onPlayerComplete.listen((_) => print('AudioService: playback complete'));
    // Note: onPlayerError removed; errors are caught in playBackgroundMusic()
  }
  static final AudioService instance = AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Play background music loop from assets/audio/background.mp3
  Future<void> playBackgroundMusic() async {
    try {
      print('AudioService: Attempting to play background music: ${AppAudio.jungle}');
      await _player.setVolume(1.0); // ensure volume is up
      // Play asset loop with AssetSource
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(AppAudio.jungle));
      print('AudioService: play() invoked');
    } catch (e) {
      print('AudioService: Failed to play background music: $e');
    }
  }

  /// Stop the background music
  Future<void> stopBackgroundMusic() async {
    try {
      await _player.stop();
    } catch (_) {}
  }
}
