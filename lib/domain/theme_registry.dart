import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A static, immutable registry of all available application themes.
///
/// Provides lookup by [id] with a fallback to [defaultTheme] when the
/// requested identifier is not found (e.g., corrupted or outdated preference).
class ThemeRegistry {
  ThemeRegistry._(); // prevent instantiation

  /// The five predefined themes in display order.
  static const List<AppTheme> themes = [
    AppTheme(
      id: 'light',
      displayName: 'Light',
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
    AppTheme(
      id: 'dark',
      displayName: 'Dark',
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
    AppTheme(
      id: 'ocean',
      displayName: 'Ocean',
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    AppTheme(
      id: 'sunset',
      displayName: 'Sunset',
      seedColor: Colors.deepOrange,
      brightness: Brightness.light,
    ),
    AppTheme(
      id: 'forest',
      displayName: 'Forest',
      seedColor: Colors.green,
      brightness: Brightness.dark,
    ),
  ];

  /// The default theme used when no preference is saved or the saved ID
  /// does not match any known theme.
  static const AppTheme defaultTheme = AppTheme(
    id: 'light',
    displayName: 'Light',
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  );

  /// Returns the [AppTheme] whose [AppTheme.id] matches [id], or
  /// [defaultTheme] if no match is found.
  static AppTheme findById(String id) {
    for (final theme in themes) {
      if (theme.id == id) {
        return theme;
      }
    }
    return defaultTheme;
  }
}
