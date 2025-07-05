import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:plantgo/core/constants/app_audio.dart';

/// Singleton service to manage background audio
class AudioService with WidgetsBindingObserver {
  AudioService._internal() {
    // Debug: listen to player state changes and completion
    _player.onPlayerStateChanged.listen((state) => print('AudioService: player state -> $state'));
    _player.onPlayerComplete.listen((_) => print('AudioService: playback complete'));
    // Note: onPlayerError removed; errors are caught in playBackgroundMusic()
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }
  static final AudioService instance = AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isUserLoggedIn = false;
  bool _shouldPlayMusic = false;
  bool _isSoundEnabled = true; // Sound setting preference

  /// Set user login status
  void setUserLoggedIn(bool isLoggedIn) {
    _isUserLoggedIn = isLoggedIn;
    print('AudioService: User logged in status: $isLoggedIn');
    
    if (!isLoggedIn) {
      // User logged out, stop music
      stopBackgroundMusic();
      _shouldPlayMusic = false;
    }
  }

  /// Set sound enabled/disabled
  void setSoundEnabled(bool isEnabled) {
    _isSoundEnabled = isEnabled;
    print('AudioService: Sound enabled: $isEnabled');
    
    if (!isEnabled) {
      // Sound disabled, stop music
      stopBackgroundMusic();
    } else if (_isUserLoggedIn && _shouldPlayMusic) {
      // Sound enabled and user is logged in, play music
      playBackgroundMusic();
    }
  }

  /// Get current sound setting
  bool get isSoundEnabled => _isSoundEnabled;

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('AudioService: App lifecycle state changed to $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        if (_isUserLoggedIn && _shouldPlayMusic && _isSoundEnabled) {
          playBackgroundMusic();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App went to background or minimized
        pauseBackgroundMusic();
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        pauseBackgroundMusic();
        break;
    }
  }

  /// Play background music loop from assets/audio/background.mp3
  Future<void> playBackgroundMusic() async {
    if (!_isUserLoggedIn) {
      print('AudioService: Cannot play music - user not logged in');
      return;
    }
    
    if (!_isSoundEnabled) {
      print('AudioService: Cannot play music - sound is disabled');
      return;
    }
    
    try {
      print('AudioService: Attempting to play background music: ${AppAudio.jungle}');
      await _player.setVolume(1.0); // ensure volume is up
      // Play asset loop with AssetSource
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(AppAudio.jungle));
      _shouldPlayMusic = true;
      print('AudioService: play() invoked');
    } catch (e) {
      print('AudioService: Failed to play background music: $e');
    }
  }

  /// Pause the background music (for app lifecycle)
  Future<void> pauseBackgroundMusic() async {
    try {
      await _player.pause();
      print('AudioService: Background music paused');
    } catch (e) {
      print('AudioService: Failed to pause background music: $e');
    }
  }

  /// Stop the background music
  Future<void> stopBackgroundMusic() async {
    try {
      await _player.stop();
      _shouldPlayMusic = false;
      print('AudioService: Background music stopped');
    } catch (e) {
      print('AudioService: Failed to stop background music: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
  }
}
