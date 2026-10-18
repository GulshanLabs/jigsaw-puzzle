import 'dart:typed_data';

import 'package:glados/glados.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';

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

/// Picks two distinct PieceIds from the pieces list using a seed.
(PieceId, PieceId) _pickTwoDistinctPieceIds(List<Piece> pieces, int seed) {
  final rng = Random(seed);
  final indexA = rng.nextInt(pieces.length);
  var indexB = rng.nextInt(pieces.length - 1);
  if (indexB >= indexA) indexB++;
  return (pieces[indexA].id, pieces[indexB].id);
}

void main() {
  /// **Validates: Requirements 9.1**
  ///
  /// Property 4: Swap is its own inverse (round-trip).
  /// For any PuzzleState and distinct PieceIds A and B,
  /// state.swap(A, B).swap(B, A).placement == state.placement.
  Glados2(
    _gridSize(),
    _seed(),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 4: Swap is its own inverse',
    (int n, int seed) {
      final state = _randomPuzzleState(n, seed);
      final (a, b) = _pickTwoDistinctPieceIds(state.pieces, seed);

      final roundTripped = state.swap(a, b).swap(b, a);

      expect(
        roundTripped.placement,
        equals(state.placement),
        reason:
            'swap($a, $b).swap($b, $a) should restore original placement '
            'for ${n}x$n grid with seed $seed',
      );
    },
    tags: 'property-test',
  );

  /// **Validates: Requirements 9.2, 13.2**
  ///
  /// Property 5: Swap increments move count by exactly 1.
  /// For any PuzzleState and distinct PieceIds A and B,
  /// state.swap(A, B).moveCount == state.moveCount + 1.
  Glados2(
    _gridSize(),
    _seed(),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 5: Swap increments move count by exactly 1',
    (int n, int seed) {
      final state = _randomPuzzleState(n, seed);
      final (a, b) = _pickTwoDistinctPieceIds(state.pieces, seed);

      final afterSwap = state.swap(a, b);

      expect(
        afterSwap.moveCount,
        equals(state.moveCount + 1),
        reason:
            'swap($a, $b).moveCount should be ${state.moveCount + 1} '
            'but was ${afterSwap.moveCount} '
            'for ${n}x$n grid with seed $seed',
      );
    },
    tags: 'property-test',
  );
}
