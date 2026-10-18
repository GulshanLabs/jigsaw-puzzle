import 'dart:typed_data';

import 'package:glados/glados.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/domain/shuffle_engine.dart';

/// Generates a grid size N in {2, 3, 4, 5, 6}.
Generator<int> _gridSize() => any.choose([2, 3, 4, 5, 6]);

/// Creates N×N pieces in solved order for a given grid size.
List<Piece> _solvedPieces(int n) {
  return [
    for (var i = 0; i < n * n; i++)
      Piece(
        id: PieceId(i ~/ n, i % n),
        imageBytes: Uint8List.fromList([i]),
      ),
  ];
}

/// Checks whether [pieces] are in solved order.
/// Solved order means positions are in strictly ascending row-major order.
bool _isSolvedOrder(List<Piece> pieces, int n) {
  for (var i = 1; i < pieces.length; i++) {
    final prev = pieces[i - 1].id;
    final curr = pieces[i].id;
    if (prev.row > curr.row ||
        (prev.row == curr.row && prev.col >= curr.col)) {
      return false;
    }
  }
  return true;
}

void main() {
  /// **Validates: Requirements 6.2**
  ///
  /// Property 3: Shuffle never produces the solved state.
  /// For any grid size N in {2,3,4,5,6}, create N×N pieces in solved order,
  /// call ShuffleEngineImpl().shuffle(pieces) and assert the result is NOT
  /// in solved order.
  Glados(
    _gridSize(),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 3: Shuffle never produces the solved state',
    (int n) {
      final pieces = _solvedPieces(n);
      final engine = ShuffleEngineImpl();
      final shuffled = engine.shuffle(pieces);

      expect(
        _isSolvedOrder(shuffled, n),
        isFalse,
        reason: 'Shuffled pieces must not be in solved order for ${n}x$n grid',
      );
    },
    tags: 'property-test',
  );
}
