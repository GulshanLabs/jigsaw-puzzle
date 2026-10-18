import 'dart:typed_data';

import 'package:glados/glados.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/domain/win_detector.dart';

/// Generates a grid size N in {2, 3, 4, 5, 6}.
Generator<int> _gridSize() => any.choose([2, 3, 4, 5, 6]);

/// Generates a random seed for shuffling the placement map.
Generator<int> _seed() => any.intInRange(0, 1 << 31);

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

/// Builds a PuzzleState with a randomly permuted placement map.
/// Uses [seed] to deterministically shuffle positions.
PuzzleState _randomPuzzleState(int n, int seed) {
  final pieces = _solvedPieces(n);
  final positions = [
    for (var r = 0; r < n; r++)
      for (var c = 0; c < n; c++) BoardPosition(r, c),
  ];
  positions.shuffle(Random(seed));

  final placement = <PieceId, BoardPosition>{};
  for (var i = 0; i < pieces.length; i++) {
    placement[pieces[i].id] = positions[i];
  }

  return PuzzleState(
    gridSize: n,
    sourceAspectRatio: 1.0,
    pieces: pieces,
    placement: placement,
  );
}

void main() {
  /// **Validates: Requirements 10.1, 10.2**
  ///
  /// Property 6: Win detection is consistent with placement.
  /// For any PuzzleState with a randomly permuted placement,
  /// WinDetectorImpl().isSolved(state) must equal state.isSolved.
  Glados2(
    _gridSize(),
    _seed(),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 6: Win detection is consistent with placement',
    (int n, int seed) {
      final state = _randomPuzzleState(n, seed);
      final detector = WinDetectorImpl();

      expect(
        detector.isSolved(state),
        equals(state.isSolved),
        reason:
            'WinDetectorImpl.isSolved must match PuzzleState.isSolved for ${n}x$n grid with seed $seed',
      );
    },
    tags: 'property-test',
  );
}
