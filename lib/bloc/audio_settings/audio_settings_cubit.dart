import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/audio_settings.dart';
import '../../services/audio_service.dart';
import '../../services/preferences_repository.dart';

/// State for [AudioSettingsCubit].
class AudioSettingsState extends Equatable {
  final bool isLoaded;
  final AudioSettings settings;

  const AudioSettingsState({
    this.isLoaded = false,
    this.settings = const AudioSettings(),
  });

  AudioSettingsState copyWith({
    bool? isLoaded,
    AudioSettings? settings,
  }) {
    return AudioSettingsState(
      isLoaded: isLoaded ?? this.isLoaded,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [isLoaded, settings];
}

/// Cubit that manages audio settings state.
class AudioSettingsCubit extends Cubit<AudioSettingsState> {
  final PreferencesRepository _preferencesRepository;
  // ignore: unused_field
  final AudioService _audioService; // kept for service lifecycle

  AudioSettingsCubit({
    required PreferencesRepository preferencesRepository,
    required AudioService audioService,
  })  : _preferencesRepository = preferencesRepository,
        _audioService = audioService,
        super(const AudioSettingsState());

  /// Load settings from persistence and emit the loaded state.
  Future<void> init() async {
    final settings = await _preferencesRepository.loadAudioSettings();
    emit(AudioSettingsState(isLoaded: true, settings: settings));
  }

  /// Flip the sound-effects toggle, persist, and emit.
  Future<void> toggleSoundEffects() async {
    final updated = state.settings.copyWith(
      soundEffectsEnabled: !state.settings.soundEffectsEnabled,
    );
    await _preferencesRepository.saveAudioSettings(updated);
    emit(state.copyWith(settings: updated));
  }
}
