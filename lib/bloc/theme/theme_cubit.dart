import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/app_theme.dart';
import '../../domain/theme_registry.dart';
import '../../services/preferences_repository.dart';

/// State for [ThemeCubit].
class ThemeState extends Equatable {
  final bool isLoaded;
  final AppTheme theme;

  const ThemeState({
    this.isLoaded = false,
    this.theme = ThemeRegistry.defaultTheme,
  });

  ThemeState copyWith({
    bool? isLoaded,
    AppTheme? theme,
  }) {
    return ThemeState(
      isLoaded: isLoaded ?? this.isLoaded,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object?> get props => [isLoaded, theme];
}

/// Cubit that manages the active color theme.
///
/// Mirrors the [AudioSettingsCubit] lifecycle: loads the persisted theme on
/// startup via [init], emits theme changes, and persists selections through
/// [PreferencesRepository].
class ThemeCubit extends Cubit<ThemeState> {
  final PreferencesRepository _preferencesRepository;

  ThemeCubit({
    required PreferencesRepository preferencesRepository,
  })  : _preferencesRepository = preferencesRepository,
        super(const ThemeState());

  /// Load the persisted theme from storage and emit the loaded state.
  ///
  /// If no theme ID is saved, defaults to [ThemeRegistry.defaultTheme].
  /// If the saved ID does not match any known theme, falls back to the
  /// default and persists the corrected ID.
  Future<void> init() async {
    try {
      final savedId = await _preferencesRepository.loadThemeId();

      if (savedId == null) {
        // First launch — use default theme.
        emit(const ThemeState(isLoaded: true));
        return;
      }

      final theme = ThemeRegistry.findById(savedId);

      // If the saved ID was invalid, findById returns the default.
      // Persist the corrected ID so we don't repeat the fallback.
      if (theme.id != savedId) {
        try {
          await _preferencesRepository.saveThemeId(theme.id);
        } catch (_) {
          // Persistence failure is non-fatal — we still emit the state.
        }
      }

      emit(ThemeState(isLoaded: true, theme: theme));
    } catch (_) {
      // SharedPreferences read failed — fall back to Light theme.
      emit(const ThemeState(isLoaded: true));
    }
  }

  /// Select a new theme by [themeId], persist it, and emit the updated state.
  ///
  /// If [themeId] does not match a known theme, [ThemeRegistry.findById]
  /// returns the default theme.
  Future<void> selectTheme(String themeId) async {
    final theme = ThemeRegistry.findById(themeId);

    try {
      await _preferencesRepository.saveThemeId(theme.id);
    } catch (_) {
      // Persistence failure is non-fatal — still update the UI.
    }

    emit(ThemeState(isLoaded: true, theme: theme));
  }
}
