import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/theme/theme_cubit.dart';
import '../../domain/app_theme.dart';
import '../../domain/theme_registry.dart';

/// A horizontal scrollable row of tappable theme swatches.
///
/// Each swatch displays a circular color preview filled with the theme's
/// [AppTheme.seedColor] and the [AppTheme.displayName] below it. The
/// currently active theme shows a check mark overlay.
///
/// Tapping a swatch calls [ThemeCubit.selectTheme] with the theme's ID.
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ThemeRegistry.themes.map((theme) {
              final isActive = theme.id == state.theme.id;
              return _ThemeSwatch(
                theme: theme,
                isActive: isActive,
                onTap: () =>
                    context.read<ThemeCubit>().selectTheme(theme.id),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// A single tappable theme swatch with a circular color preview and label.
class _ThemeSwatch extends StatelessWidget {
  final AppTheme theme;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.theme,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = isActive
        ? 'Select ${theme.displayName} theme, currently active'
        : 'Select ${theme.displayName} theme';

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.seedColor,
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                              width: 2,
                            )
                          : null,
                    ),
                  ),
                  if (isActive)
                    Icon(
                      Icons.check,
                      color: _contrastingIconColor(theme.seedColor),
                      size: 24,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                theme.displayName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns white or black depending on which contrasts better with [color].
  static Color _contrastingIconColor(Color color) {
    // Use relative luminance to pick a readable check mark color.
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
