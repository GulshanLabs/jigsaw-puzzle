import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/timer/timer_bloc.dart';
import 'package:jigsaw_puzzle_game/ui/widgets/puzzle_piece_widget.dart';
import 'package:jigsaw_puzzle_game/ui/widgets/settings_action.dart';

/// The main puzzle board screen.
///
/// Displays an N×N grid of [PuzzlePieceWidget]s with a persistent header
/// showing the move count and elapsed timer. Navigates to the completion
/// screen when the puzzle is solved.
class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solve the Puzzle'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Exit puzzle',
          onPressed: () {
            context.read<PuzzleBloc>().add(const NewPuzzleRequested());
          },
        ),
        actions: [buildSettingsAction(context)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _StatsHeader(),
            const SizedBox(height: 8),
            const Expanded(child: _PuzzleGrid()),
          ],
        ),
      ),
    );
  }
}

/// Persistent header showing move count and elapsed time.
class _StatsHeader extends StatelessWidget {
  const _StatsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BlocBuilder<PuzzleBloc, PuzzleBlocState>(
            builder: (context, state) {
              final moveCount =
                  state is BoardActive ? state.state.moveCount : 0;
              return _StatChip(
                icon: Icons.swap_horiz,
                label: 'Moves',
                value: '$moveCount',
              );
            },
          ),
          BlocBuilder<TimerBloc, TimerState>(
            builder: (context, state) {
              final seconds = state.seconds;
              final minutes = seconds ~/ 60;
              final secs = seconds % 60;
              final formatted =
                  '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
              return _StatChip(
                icon: Icons.timer,
                label: 'Time',
                value: formatted,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Support dynamic text size via the platform's text scaler.
    final textScaler = MediaQuery.textScalerOf(context);
    final iconSize = textScaler.scale(20);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

/// The puzzle grid with square layout.
class _PuzzleGrid extends StatelessWidget {
  const _PuzzleGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PuzzleBloc, PuzzleBlocState>(
      builder: (context, state) {
        if (state is! BoardActive) {
          return const SizedBox.shrink();
        }

        final puzzleState = state.state;
        final selectedId = state.selectedPieceId;

        return Padding(
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sourceAspectRatio = puzzleState.sourceAspectRatio;
              double boardWidth, boardHeight;
              if (constraints.maxWidth / constraints.maxHeight >
                  sourceAspectRatio) {
                boardHeight = constraints.maxHeight;
                boardWidth = boardHeight * sourceAspectRatio;
              } else {
                boardWidth = constraints.maxWidth;
                boardHeight = boardWidth / sourceAspectRatio;
              }

              final n = puzzleState.gridSize;
              final cellWidth = boardWidth / n;
              final cellHeight = boardHeight / n;

              return Center(
                child: SizedBox(
                  width: boardWidth,
                  height: boardHeight,
                  child: Stack(
                    children: puzzleState.pieces.map((piece) {
                      final pos = puzzleState.placement[piece.id]!;
                      final isSelected = selectedId == piece.id;

                      return AnimatedPositioned(
                        key: ValueKey(piece.id),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: pos.col * cellWidth,
                        top: pos.row * cellHeight,
                        width: cellWidth,
                        height: cellHeight,
                        child: PuzzlePieceWidget(
                          piece: piece,
                          isSelected: isSelected,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
