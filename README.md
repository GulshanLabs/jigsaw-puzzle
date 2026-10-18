# Jigsaw Puzzle

A Flutter-based jigsaw puzzle game where you take a photo (or pick from gallery), slice it into pieces, and solve the puzzle by tapping and swapping pieces back into the correct positions.

- **App name:** Jigsaw Puzzle
- **App ID:** `com.nousvara.puzzle` (Android `applicationId` and iOS bundle identifier). Never change this after the first public release: Android treats a different ID as a different app, so existing users would not get updates.
- **License:** [MIT](LICENSE) — anyone may use, change and redistribute the code, as long as the copyright notice is kept.

Runs on **Android and iOS**. Those are the only platform projects in this repository.

## Privacy

The photo you choose never leaves your device. It is sliced and shuffled in memory, and the only thing saved is your settings (sound on/off and chosen theme) in local app storage. There is no backend, no account, no analytics, and no network calls.

## Getting started

You need the Flutter SDK (stable channel) and either an Android or iOS setup. This project was built against the stable revision recorded in [`.metadata`](.metadata), with Dart `^3.9.2` and Flutter `>=3.35.0` as resolved in `pubspec.lock`.

```bash
flutter --version          # check your install
flutter pub get            # fetch dependencies
flutter run                # run on a connected device or emulator
```

Useful checks while developing:

```bash
flutter analyze
flutter test
```

## Features

- Take a photo or pick from gallery
- Choose grid size from 2×2 to 6×6
- Tap to select a piece, tap another to swap them
- Move counter and timer
- Sound effects on piece tap and swap (toggleable via settings gear icon)
- Five colour themes (Light, Dark, Ocean, Sunset, Forest), switchable in settings
- App version display on home screen
- Settings persist across app sessions

## Project Structure

The project has two types of folders — **platform folders** and **your code**.

### Platform folders (you rarely touch these)

- `android/` — Android-specific config (Gradle build files, AndroidManifest.xml, app icon)
- `ios/` — iOS-specific config (Xcode project, Info.plist)
- `docs/specs/` — The requirements and design notes the features were built from

Two more folders appear once you build, and neither is in version control: `build/` (generated output such as APKs) and `.dart_tool/` (Dart tooling cache — never edit).

### Your code (this is where you work)

- `lib/` — All your Dart source code
- `test/` — All your test files
- `assets/` — Audio files, images, etc.
- `tool/` — Utility scripts (like the audio generator)
- `pubspec.yaml` — The most important config file (dependencies, assets, app version)

## How `lib/` is organized

The app uses the **BLoC pattern** (Business Logic Component), which separates code into layers:

```
lib/
├── main.dart                ← App entry point. Wires everything together.
├── bloc/                    ← State management (the "brain")
│   ├── puzzle/              ← Puzzle game logic (piece selection, swapping, win detection)
│   ├── timer/               ← Game timer
│   ├── audio_settings/      ← Sound effects on/off toggle
│   └── theme/               ← Selected colour theme
├── domain/                  ← Data models & business logic (no Flutter dependency)
│   ├── models.dart          ← Piece, PieceId, BoardPosition, PuzzleState
│   ├── audio_settings.dart  ← AudioSettings model (soundEffectsEnabled)
│   ├── app_theme.dart       ← AppTheme model (seed colour + brightness)
│   ├── theme_registry.dart  ← The five selectable themes
│   ├── contrast_calculator.dart ← WCAG contrast ratio helper
│   ├── interfaces.dart      ← Abstract interfaces (PermissionService, ImagePicker, etc.)
│   ├── exceptions.dart      ← Domain-level error types
│   ├── image_processor.dart ← Slices an image into N×N pieces
│   ├── shuffle_engine.dart  ← Randomizes piece positions
│   └── win_detector.dart    ← Checks if puzzle is solved
├── services/                ← External integrations (device APIs)
│   ├── audio_service.dart           ← Plays tap/swap sounds via audioplayers
│   ├── preferences_repository.dart  ← Saves settings to SharedPreferences
│   ├── permission_service.dart      ← Camera/gallery permissions
│   └── image_picker_service.dart    ← Picks photos from camera/gallery
└── ui/                      ← Everything visual
    ├── screens/             ← Full-page screens
    │   ├── photo_source_screen.dart  ← Home: pick camera or gallery
    │   ├── grid_config_screen.dart   ← Choose grid size (2×2 to 6×6)
    │   ├── board_screen.dart         ← The puzzle board (tap & swap pieces)
    │   └── completion_screen.dart    ← Victory screen with stats
    └── widgets/             ← Reusable UI components
        ├── puzzle_piece_widget.dart   ← Single puzzle piece tile
        ├── settings_action.dart       ← Gear icon button
        ├── settings_bottom_sheet.dart ← Settings popup with sound toggle
        └── theme_selector.dart        ← Theme swatch picker
```

## How the app flows

1. **`main.dart`** starts the app. It creates all the services (audio, preferences, permissions, image picker) and BLoCs (puzzle, timer, audio settings), then provides them to the widget tree using `BlocProvider` and `RepositoryProvider`.

2. **PhotoSourceScreen** — User sees "Take a Photo" or "Choose from Gallery". Tapping either requests permissions, then opens the camera/gallery.

3. **GridConfigScreen** — User sees a preview of their photo with a grid overlay. They pick a size (2×2 through 6×6) and tap Confirm. The image gets sliced into pieces.

4. **BoardScreen** — The puzzle! Pieces are shuffled. User taps a piece to select it (tap sound plays), then taps another to swap them (swap sound plays). The timer runs. When all pieces are in the right position, the win detector triggers.

5. **CompletionScreen** — Shows the solved image, move count, and time. Options to play again or start a new puzzle.

The `_AppShell` widget in `main.dart` listens to `PuzzleBloc` state and swaps between these screens automatically.

## Key files to edit for common changes

| What you want to change | File to edit |
|---|---|
| App name, version, dependencies | `pubspec.yaml` |
| App icon | `pubspec.yaml` (flutter_launcher_icons section) + run `dart run flutter_launcher_icons` |
| Sound effects (the actual audio) | Run `dart run tool/generate_audio.dart` or replace files in `assets/audio/` |
| Sound toggle behavior | `lib/bloc/audio_settings/audio_settings_cubit.dart` |
| Available themes and their colours | `lib/domain/theme_registry.dart` |
| How pieces interact (tap/swap logic) | `lib/ui/widgets/puzzle_piece_widget.dart` |
| Screen layouts | Files in `lib/ui/screens/` |
| Grid sizes available | `lib/ui/screens/grid_config_screen.dart` (the `_gridSizes` list) |
| Win detection logic | `lib/domain/win_detector.dart` |
| How the image gets sliced | `lib/domain/image_processor.dart` |
| Android-specific config (permissions, splash screen) | `android/app/src/main/AndroidManifest.xml` |
| iOS-specific config | `ios/Runner/Info.plist` |

## Building

All commands run from the repository root.

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Google Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Without a keystore, both commands fall back to debug signing (see [Release signing](#release-signing)). That is fine for testing on your own device, but not for distribution.

### iOS (requires a Mac with Xcode)

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode to archive and distribute. You need an Apple Developer account for device deployment, and you will need to set your own bundle identifier and signing team.

### Other platforms

Desktop and web projects are not part of this repository. If you want them, generate the platform folders yourself and expect to verify plugin support, since `image_picker` behaves differently on desktop (no system camera UI) and `permission_handler` does not cover every platform:

```bash
flutter create --platforms=web,macos,windows,linux .
```

## Running tests

```bash
flutter test
```

## Regenerating audio assets

The audio files are generated programmatically (no external downloads needed):

```bash
dart run tool/generate_audio.dart
```

This creates `assets/audio/tap_sound.wav` (soft click) and `assets/audio/swap_sound.wav` (smooth whoosh).

## Release signing

You do not need any of this to build and run the app. It only matters if you want to distribute your own signed build.

Release signing needs two things that are **not** in this repository, because they are private to whoever publishes the app:

- a keystore file (`.jks`), which is the signing identity
- `android/key.properties`, which points at that keystore and holds its passwords

Both are gitignored (see `android/.gitignore`). If `android/key.properties` is missing, Gradle falls back to debug signing so the build still works.

### Signing your own build

1. Create a keystore once, outside the repository. On a Mac with Android Studio installed, `keytool` comes with Android Studio's Java:
   ```bash
   "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkeypair -v \
     -keystore ~/zigsaw-release.jks -alias zigsaw \
     -keyalg RSA -keysize 2048 -validity 10000
   ```
   It asks for a password and a few details (name, organisation, country). Use the same password when asked for the key password.
2. Put your values in `android/key.properties`:
   ```properties
   storePassword=<the password you chose>
   keyPassword=<the same password>
   keyAlias=zigsaw
   storeFile=/Users/<you>/zigsaw-release.jks
   ```
3. Build as usual with `flutter build apk --release` or `flutter build appbundle --release`.
4. Check it worked — the signer should be your name, not `CN=Android Debug`:
   ```bash
   "$(ls -d ~/Library/Android/sdk/build-tools/*/apksigner | tail -1)" verify --print-certs \
     build/app/outputs/flutter-apk/app-release.apk
   ```
   (If it says it cannot find Java, prefix the command with
   `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`.)

> **Back up the keystore and remember its passwords.** If you lose the keystore, you cannot ship updates to an existing Play Store listing under the same identity. Never commit the keystore or `key.properties`, and never share them in a source archive.

### Why signing matters

- **Sideloading (sharing APKs directly):** a release-signed APK triggers fewer security warnings than a debug-signed one. Users still have to allow installs from unknown sources.
- **Google Play:** signing is mandatory. You upload a signed AAB, and Play App Signing re-signs it for each device.

## Before you distribute your own build

The official app uses the ID `com.nousvara.puzzle`. If you publish your own modified version, change the ID to a domain you control (in `android/app/build.gradle.kts` and in the Xcode project) so it does not clash with the official app. The MIT license lets you do this; keep the copyright notice from [LICENSE](LICENSE).

When attaching the APK to a GitHub release, rename `app-release.apk` to `jigsaw-puzzle.apk` so the download has a recognisable name.
