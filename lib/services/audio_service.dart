import 'package:audioplayers/audioplayers.dart';

/// Wraps [audioplayers] for sound effect playback.
abstract class AudioService {
  /// Play the tap/select sound effect (one-shot).
  Future<void> playTapSound();

  /// Play the swap sound effect (one-shot).
  Future<void> playSwapSound();

  /// Release all audio resources.
  Future<void> dispose();
}

/// Concrete implementation of [AudioService] using the `audioplayers` package.
///
/// Uses a single [AudioPlayer] instance for one-shot sound effects.
/// All player calls are wrapped in try/catch to silently handle failures.
class AudioServiceImpl implements AudioService {
  final AudioPlayer _sfxPlayer;

  AudioServiceImpl({
    AudioPlayer? sfxPlayer,
  }) : _sfxPlayer = sfxPlayer ?? AudioPlayer();

  @override
  Future<void> playTapSound() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/tap_sound.wav'));
    } catch (_) {
      // Silently handle audio failures
    }
  }

  @override
  Future<void> playSwapSound() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/swap_sound.wav'));
    } catch (_) {
      // Silently handle audio failures
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _sfxPlayer.dispose();
    } catch (_) {
      // Silently handle audio failures
    }
  }
}
