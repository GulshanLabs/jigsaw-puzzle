import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/audio_settings/audio_settings_cubit.dart';

import 'theme_selector.dart';

/// A bottom sheet that displays audio settings toggles.
class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioSettingsCubit, AudioSettingsState>(
      builder: (context, state) {
        final cubit = context.read<AudioSettingsCubit>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Sound Effects'),
                  subtitle:
                      const Text('Play sounds on piece tap and swap'),
                  value: state.settings.soundEffectsEnabled,
                  onChanged: (_) => cubit.toggleSoundEffects(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                const ThemeSelector(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
