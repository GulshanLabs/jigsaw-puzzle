# Requirements Document

## Introduction

This feature adds an audio system and a settings dialog to the Jigsaw Puzzle Game Flutter app. Users will be able to toggle background music and sound effects (tap and swap sounds) from a gear icon accessible on every screen. Sound preferences persist across app sessions using local storage. Additionally, the app version number is displayed on the PhotoSourceScreen (home screen).

## Glossary

- **App**: The Jigsaw Puzzle Game Flutter application
- **Settings_Dialog**: A modal bottom sheet or dialog opened via the gear icon, containing audio preference toggles
- **Audio_Service**: The domain-level service responsible for playing, pausing, and managing all audio playback
- **Background_Music**: A continuously looping ambient audio track that plays while the App is in the foreground
- **Sound_Effects**: Short audio clips triggered by specific user interactions on the BoardScreen (tap sound and swap sound)
- **Tap_Sound**: A sound effect played when the user selects a puzzle piece on the BoardScreen
- **Swap_Sound**: A sound effect played when two selected puzzle pieces are swapped on the BoardScreen
- **Preferences_Repository**: A persistence layer that stores and retrieves user audio preferences using SharedPreferences
- **Audio_Settings_Bloc**: The BLoC responsible for managing audio settings state (sound effects enabled, background music enabled)
- **PhotoSourceScreen**: The home screen where the user chooses a photo source
- **BoardScreen**: The screen where the user solves the puzzle by tapping and swapping pieces
- **AppBar**: The top navigation bar present on each screen

## Requirements

### Requirement 1: Settings Gear Icon

**User Story:** As a player, I want a settings gear icon on every screen, so that I can access audio preferences at any time.

#### Acceptance Criteria

1. THE App SHALL display a gear icon (Icons.settings) in the top-right actions area of the AppBar on every screen (PhotoSourceScreen, GridConfigScreen, BoardScreen, CompletionScreen).
2. WHEN the user taps the gear icon, THE App SHALL open the Settings_Dialog as a modal bottom sheet.
3. THE Settings_Dialog SHALL contain exactly two toggle switches: one labeled "Sound Effects" and one labeled "Background Music".
4. THE Settings_Dialog SHALL reflect the current persisted state of each toggle when opened.
5. WHEN the user changes a toggle in the Settings_Dialog, THE Audio_Settings_Bloc SHALL update the corresponding audio preference immediately.

### Requirement 2: Background Music

**User Story:** As a player, I want soft ambient background music while using the app, so that the puzzle-solving experience feels more immersive.

#### Acceptance Criteria

1. WHEN the App starts and background music is enabled in preferences, THE Audio_Service SHALL begin playing Background_Music in a continuous loop.
2. WHILE Background_Music is playing, THE Audio_Service SHALL loop the track seamlessly without gaps or silence between repetitions.
3. WHEN the user disables background music via the Settings_Dialog, THE Audio_Service SHALL stop Background_Music playback immediately.
4. WHEN the user enables background music via the Settings_Dialog, THE Audio_Service SHALL resume Background_Music playback from the beginning.
5. WHEN the App transitions to the background (lifecycle paused), THE Audio_Service SHALL pause Background_Music playback.
6. WHEN the App returns to the foreground (lifecycle resumed) and background music is enabled, THE Audio_Service SHALL resume Background_Music playback.

### Requirement 3: Sound Effects

**User Story:** As a player, I want audible feedback when I interact with puzzle pieces, so that tapping and swapping pieces feels responsive.

#### Acceptance Criteria

1. WHEN the user taps a puzzle piece on the BoardScreen and sound effects are enabled, THE Audio_Service SHALL play the Tap_Sound.
2. WHEN two puzzle pieces are swapped on the BoardScreen and sound effects are enabled, THE Audio_Service SHALL play the Swap_Sound.
3. WHILE sound effects are disabled, THE Audio_Service SHALL not play Tap_Sound or Swap_Sound regardless of user interaction.
4. THE Tap_Sound and Swap_Sound SHALL be distinct audio clips so the user can differentiate between selection and swap actions.

### Requirement 4: Audio Preference Persistence

**User Story:** As a player, I want my audio preferences remembered between sessions, so that I do not have to reconfigure settings each time I open the app.

#### Acceptance Criteria

1. WHEN the user changes a sound effects or background music toggle, THE Preferences_Repository SHALL persist the new value to local storage (SharedPreferences).
2. WHEN the App starts, THE Preferences_Repository SHALL load previously saved audio preferences and apply them.
3. IF no previously saved preferences exist, THEN THE Preferences_Repository SHALL default sound effects to enabled and background music to enabled.

### Requirement 5: Audio Asset Generation

**User Story:** As a developer, I want placeholder audio assets generated programmatically, so that the audio system can be tested without external audio file downloads.

#### Acceptance Criteria

1. THE App SHALL include three WAV audio asset files: one for Background_Music, one for Tap_Sound, and one for Swap_Sound, located in an `assets/audio/` directory.
2. THE App SHALL register the `assets/audio/` directory in pubspec.yaml under the flutter assets section.
3. THE Audio_Service SHALL use the `audioplayers` package to play all audio assets.

### Requirement 6: Version Number Display

**User Story:** As a player, I want to see the app version number on the home screen, so that I know which version of the app I am using.

#### Acceptance Criteria

1. THE PhotoSourceScreen SHALL display the app version string (e.g., "v1.0.0") in a visible location below the action buttons.
2. THE App SHALL read the version number from the package info at runtime rather than hardcoding the value.
3. THE version label SHALL use a subdued text style consistent with the app theme so it does not distract from primary UI elements.
