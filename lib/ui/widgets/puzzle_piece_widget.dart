import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/audio_settings/audio_settings_cubit.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/services/audio_service.dart';

/// A single puzzle piece tile that displays its image, highlights when
/// selected, and dispatches [PieceTapped] on tap.
class PuzzlePieceWidget extends StatelessWidget {
  const PuzzlePieceWidget({
    super.key,
    required this.piece,
    required this.isSelected,
  });

  final Piece piece;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: isSelected
            ? Border.all(color: Colors.blueAccent, width: 3)
            : Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Image.memory(
        piece.imageBytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );

    return Semantics(
      label: 'Puzzle piece row ${piece.id.row + 1} column ${piece.id.col + 1}'
          '${isSelected ? ', selected' : ''}',
      button: true,
      selected: isSelected,
      onTap: () => _onTap(context),
      child: GestureDetector(
        onTap: () => _onTap(context),
        child: content,
      ),
    );
  }

  void _onTap(BuildContext context) {
    final puzzleState = context.read<PuzzleBloc>().state;
    final audioSettings = context.read<AudioSettingsCubit>().state;
    final audioService = context.read<AudioService>();

    if (audioSettings.settings.soundEffectsEnabled) {
      if (puzzleState is BoardActive && puzzleState.selectedPieceId != null) {
        if (puzzleState.selectedPieceId != piece.id) {
          audioService.playSwapSound();
        }
      } else {
        audioService.playTapSound();
      }
    }

    context.read<PuzzleBloc>().add(PieceTapped(piece.id));
  }
}
