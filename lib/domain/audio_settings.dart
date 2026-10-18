import 'package:equatable/equatable.dart';

/// Holds the user's audio preferences for sound effects.
class AudioSettings extends Equatable {
  final bool soundEffectsEnabled;

  const AudioSettings({
    this.soundEffectsEnabled = true,
  });

  AudioSettings copyWith({
    bool? soundEffectsEnabled,
  }) {
    return AudioSettings(
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
    );
  }

  @override
  List<Object?> get props => [soundEffectsEnabled];
}
