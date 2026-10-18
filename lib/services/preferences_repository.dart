import 'package:shared_preferences/shared_preferences.dart';

import '../domain/audio_settings.dart';

/// Abstracts persistence of audio settings and theme preferences.
abstract class PreferencesRepository {
  /// Load saved audio settings. Returns defaults if none saved.
  Future<AudioSettings> loadAudioSettings();

  /// Persist audio settings.
  Future<void> saveAudioSettings(AudioSettings settings);

  /// Load the persisted theme identifier. Returns null if none saved.
  Future<String?> loadThemeId();

  /// Persist the selected theme identifier.
  Future<void> saveThemeId(String themeId);
}

/// Concrete implementation backed by [SharedPreferences].
class PreferencesRepositoryImpl implements PreferencesRepository {
  static const _keySfxEnabled = 'audio_sfx_enabled';
  static const _keyThemeId = 'theme_id';

  final SharedPreferences _prefs;

  PreferencesRepositoryImpl(this._prefs);

  @override
  Future<AudioSettings> loadAudioSettings() async {
    final sfx = _prefs.getBool(_keySfxEnabled) ?? true;
    return AudioSettings(soundEffectsEnabled: sfx);
  }

  @override
  Future<void> saveAudioSettings(AudioSettings settings) async {
    await _prefs.setBool(_keySfxEnabled, settings.soundEffectsEnabled);
  }

  @override
  Future<String?> loadThemeId() async {
    return _prefs.getString(_keyThemeId);
  }

  @override
  Future<void> saveThemeId(String themeId) async {
    await _prefs.setString(_keyThemeId, themeId);
  }
}
