import 'package:equatable/equatable.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';

/// Base class for all puzzle events.
abstract class PuzzleEvent extends Equatable {
  const PuzzleEvent();

  @override
  List<Object?> get props => [];
}

/// User selected a photo source (camera or gallery).
class PhotoSourceSelected extends PuzzleEvent {
  final PhotoSource source;

  const PhotoSourceSelected(this.source);

  @override
  List<Object?> get props => [source];
}

/// User selected a grid size N.
class GridSizeSelected extends PuzzleEvent {
  final int n;

  const GridSizeSelected(this.n);

  @override
  List<Object?> get props => [n];
}

/// User confirmed the grid size selection.
class GridSizeConfirmed extends PuzzleEvent {
  const GridSizeConfirmed();
}

/// User tapped a piece on the board.
class PieceTapped extends PuzzleEvent {
  final PieceId pieceId;

  const PieceTapped(this.pieceId);

  @override
  List<Object?> get props => [pieceId];
}

/// User requested to play again with the same image and grid.
class PlayAgainRequested extends PuzzleEvent {
  const PlayAgainRequested();
}

/// User requested a new puzzle (back to source selection).
class NewPuzzleRequested extends PuzzleEvent {
  const NewPuzzleRequested();
}
