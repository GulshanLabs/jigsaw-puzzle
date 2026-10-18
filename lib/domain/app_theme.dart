import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Represents a single color theme for the application.
///
/// Each theme has a unique [id] for persistence, a [displayName] for the UI,
/// a [seedColor] used with `ColorScheme.fromSeed`, and a [brightness] that
/// controls whether the generated scheme is light or dark.
class AppTheme extends Equatable {
  final String id;
  final String displayName;
  final Color seedColor;
  final Brightness brightness;

  const AppTheme({
    required this.id,
    required this.displayName,
    required this.seedColor,
    required this.brightness,
  });

  @override
  List<Object?> get props => [id, displayName, seedColor, brightness];
}
