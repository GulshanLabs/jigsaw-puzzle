import 'package:jigsaw_puzzle_game/domain/interfaces.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';

/// Concrete implementation of [WinDetector].
///
/// Returns `true` iff every piece's current board position matches
/// its correct position, i.e. `BoardPosition(piece.id.row, piece.id.col)`.
class WinDetectorImpl implements WinDetector {
  @override
  bool isSolved(PuzzleState state) {
    return state.pieces.every(
      (p) => state.placement[p.id] == BoardPosition(p.id.row, p.id.col),
    );
  }
}
