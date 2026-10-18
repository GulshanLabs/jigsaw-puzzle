import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jigsaw_puzzle_game/bloc/puzzle/puzzle_bloc.dart';
import 'package:jigsaw_puzzle_game/ui/widgets/settings_action.dart';

/// Screen for selecting the grid size (2×2 through 6×6) before starting the puzzle.
///
/// Displays a preview of the acquired image with an overlay of grid lines
/// matching the currently selected N. The user picks a size and taps Confirm.
///
/// Expects [PuzzleBloc] to be available via `BlocProvider`.
class GridConfigScreen extends StatelessWidget {
  const GridConfigScreen({super.key});

  static const List<int> _gridSizes = [2, 3, 4, 5, 6];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PuzzleBloc, PuzzleBlocState>(
      listener: (context, state) {
        if (state is ImageProcessingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to process image. Please try again.'),
            ),
          );
          // Navigation back to source selection is handled by the app shell
          // when PuzzleBloc emits PuzzleInitial or the user retries.
        }
      },
      builder: (context, state) {
        if (state is ProcessingImage) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Configure Puzzle'),
              actions: [buildSettingsAction(context)],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          _ImagePreviewWithGrid(
                            imageBytes: state.imageBytes,
                            gridSize: state.gridSize,
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Slicing your image...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is! ConfiguringGrid) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Configure Puzzle'),
              actions: [buildSettingsAction(context)],
            ),
            body: const SizedBox.shrink(),
          );
        }

        final imageBytes = state.imageBytes;
        final selectedN = state.selectedN;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Configure Puzzle'),
            actions: [buildSettingsAction(context)],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: _ImagePreviewWithGrid(
                      imageBytes: imageBytes,
                      gridSize: selectedN,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GridSizeSelector(
                    selectedN: selectedN,
                    onSelected: (n) {
                      context.read<PuzzleBloc>().add(GridSizeSelected(n));
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Semantics(
                      label: 'Confirm grid size selection',
                      button: true,
                      child: ElevatedButton(
                        onPressed: selectedN != null
                            ? () => context
                                .read<PuzzleBloc>()
                                .add(const GridSizeConfirmed())
                            : null,
                        child: const Text('Confirm'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Displays the acquired image with an overlay of grid lines.
class _ImagePreviewWithGrid extends StatelessWidget {
  const _ImagePreviewWithGrid({
    required this.imageBytes,
    this.gridSize,
  });

  final Uint8List imageBytes;
  final int? gridSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Center(
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                ),
              ),
              if (gridSize != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridOverlayPainter(gridSize: gridSize!),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Paints square grid lines over the image preview.
class _GridOverlayPainter extends CustomPainter {
  _GridOverlayPainter({required this.gridSize});

  final int gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;

    // Draw vertical lines.
    for (var i = 1; i < gridSize; i++) {
      final x = cellWidth * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines.
    for (var i = 1; i < gridSize; i++) {
      final y = cellHeight * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridOverlayPainter oldDelegate) =>
      oldDelegate.gridSize != gridSize;
}

/// Row of selectable chips for grid size options.
class _GridSizeSelector extends StatelessWidget {
  const _GridSizeSelector({
    required this.selectedN,
    required this.onSelected,
  });

  final int? selectedN;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: GridConfigScreen._gridSizes.map((n) {
        final isSelected = selectedN == n;
        return Semantics(
          label: '$n by $n grid, ${n * n} pieces',
          selected: isSelected,
          child: ChoiceChip(
            label: Text('$n×$n'),
            selected: isSelected,
            onSelected: (_) => onSelected(n),
          ),
        );
      }).toList(),
    );
  }
}
