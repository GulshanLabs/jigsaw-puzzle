import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/domain/interfaces.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/ui/widgets/settings_action.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Screen that lets the user choose between taking a photo or picking from gallery.
///
/// Expects [PuzzleBloc] and [PermissionService] to be available in the widget
/// tree (via `BlocProvider` and `RepositoryProvider` respectively).
class PhotoSourceScreen extends StatelessWidget {
  const PhotoSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PuzzleBloc, PuzzleBlocState>(
      listener: (context, state) {
        if (state is PermissionDenied) {
          _showPermissionDeniedDialog(context, state);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jigsaw Puzzle'),
          actions: [buildSettingsAction(context)],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: MediaQuery.textScalerOf(context).scale(80),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Choose a photo to create your puzzle',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap any two pieces to swap them and solve the puzzle!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Semantics(
                    label: 'Take a Photo',
                    button: true,
                    child: ElevatedButton.icon(
                      onPressed: () => context
                          .read<PuzzleBloc>()
                          .add(const PhotoSourceSelected(PhotoSource.camera)),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take a Photo'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Semantics(
                    label: 'Choose from Gallery',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: () => context
                          .read<PuzzleBloc>()
                          .add(const PhotoSourceSelected(PhotoSource.gallery)),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final versionText = snapshot.hasData
                        ? 'v${snapshot.data!.version}'
                        : snapshot.hasError
                            ? 'v?.?.?'
                            : '';
                    return Text(
                      versionText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPermissionDeniedDialog(
    BuildContext context,
    PermissionDenied state,
  ) {
    final sourceName =
        state.source == PhotoSource.camera ? 'camera' : 'photo library';
    final message = state.isPermanent
        ? 'Access to the $sourceName has been permanently denied. '
            'Please open Settings to enable it.'
        : 'Access to the $sourceName is required. '
            'Please grant permission to continue.';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PermissionService>().openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
