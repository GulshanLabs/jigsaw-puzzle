import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/audio_settings/audio_settings_cubit.dart';
import 'package:jigsaw_puzzle_game/bloc/theme/theme_cubit.dart';
import 'package:jigsaw_puzzle_game/ui/widgets/settings_bottom_sheet.dart';

/// Builds a settings gear [IconButton] for use in [AppBar.actions].
///
/// Tapping the icon opens a [SettingsBottomSheet] as a modal bottom sheet,
/// passing both [AudioSettingsCubit] and [ThemeCubit] from the parent
/// [context] via [MultiBlocProvider] so the sheet can read and toggle
/// audio settings and select themes.
Widget buildSettingsAction(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.settings),
    tooltip: 'Settings',
    onPressed: () => showModalBottomSheet(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: context.read<AudioSettingsCubit>(),
          ),
          BlocProvider.value(
            value: context.read<ThemeCubit>(),
          ),
        ],
        child: const SettingsBottomSheet(),
      ),
    ),
  );
}
