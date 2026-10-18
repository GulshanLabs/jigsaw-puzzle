import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/ui/widgets/settings_action.dart';

/// The completion screen displayed after the puzzle is solved.
///
/// Shows the fully reconstructed source image (pieces reassembled in correct
/// order), the final move count, elapsed time, and two action buttons:
/// "Play Again" and "New Puzzle".
class CompletionScreen extends StatelessWidget {
  const CompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PuzzleBloc, PuzzleBlocState>(
      builder: (context, state) {
        if (state is! PuzzleSolved) {
          return const SizedBox.shrink();
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Puzzle Complete!'),
            automaticallyImplyLeading: false,
            actions: [buildSettingsAction(context)],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ReconstructedImage(puzzleState: state.state),
                  const SizedBox(height: 24),
                  _StatsRow(
                    moveCount: state.moveCount,
                    elapsedSeconds: state.elapsedSeconds,
                  ),
                  const SizedBox(height: 32),
                  _ActionButtons(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


/// Reassembles the puzzle pieces in their correct grid order to display
/// the fully reconstructed source image.
class _ReconstructedImage extends StatelessWidget {
  const _ReconstructedImage({required this.puzzleState});

  final PuzzleState puzzleState;

  @override
  Widget build(BuildContext context) {
    final n = puzzleState.gridSize;
    final pieces = puzzleState.pieces;

    // Build a lookup from correct grid position to piece.
    final grid = <PieceId, Piece>{};
    for (final piece in pieces) {
      grid[piece.id] = piece;
    }

    return AspectRatio(
      aspectRatio: puzzleState.sourceAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: List.generate(n, (row) {
            return Expanded(
              child: Row(
                children: List.generate(n, (col) {
                  final piece = grid[PieceId(row, col)];
                  if (piece == null) return const Expanded(child: SizedBox());
                  return Expanded(
                    child: Image.memory(
                      piece.imageBytes,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Displays the final move count and elapsed time.
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.moveCount,
    required this.elapsedSeconds,
  });

  final int moveCount;
  final int elapsedSeconds;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsedSeconds ~/ 60;
    final secs = elapsedSeconds % 60;
    final formatted =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // Support dynamic text size via the platform's text scaler.
    final textScaler = MediaQuery.textScalerOf(context);
    final iconSize = textScaler.scale(28);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Icon(Icons.swap_horiz, size: iconSize),
            const SizedBox(height: 4),
            Text(
              '$moveCount',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('Moves', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Column(
          children: [
            Icon(Icons.timer, size: iconSize),
            const SizedBox(height: 4),
            Text(
              formatted,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('Time', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}

/// The "Play Again" and "New Puzzle" action buttons.
class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: Semantics(
            label: 'Play Again',
            button: true,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<PuzzleBloc>().add(const PlayAgainRequested());
              },
              icon: const Icon(Icons.replay),
              label: const Text('Play Again'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: Semantics(
            label: 'New Puzzle',
            button: true,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<PuzzleBloc>().add(const NewPuzzleRequested());
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('New Puzzle'),
            ),
          ),
        ),
      ],
    );
  }
}
