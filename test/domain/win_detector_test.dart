import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/domain/win_detector.dart';

/// Helper: creates N×N pieces in solved order.
List<Piece> _makePieces(int n) {
  return [
    for (var r = 0; r < n; r++)
      for (var c = 0; c < n; c++)
        Piece(id: PieceId(r, c), imageBytes: Uint8List.fromList([r, c])),
  ];
}

/// Helper: builds a solved PuzzleState for an N×N grid.
PuzzleState _solvedState(int n) {
  final pieces = _makePieces(n);
  final placement = <PieceId, BoardPosition>{
    for (final p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
  };
  return PuzzleState(gridSize: n, sourceAspectRatio: 1.0, pieces: pieces, placement: placement);
}

void main() {
  late WinDetectorImpl detector;

  setUp(() {
    detector = WinDetectorImpl();
  });

  group('WinDetectorImpl — solved placement returns true', () {
    test('2×2 solved grid', () {
      expect(detector.isSolved(_solvedState(2)), isTrue);
    });

    test('3×3 solved grid', () {
      expect(detector.isSolved(_solvedState(3)), isTrue);
    });
  });

  group('WinDetectorImpl — swapping any single pair returns false (2×2)', () {
    test('swapping piece (0,0) and (0,1)', () {
      final state = _solvedState(2);
      final swapped = state.swap(const PieceId(0, 0), const PieceId(0, 1));
      expect(detector.isSolved(swapped), isFalse);
    });

    test('swapping piece (0,0) and (1,0)', () {
      final state = _solvedState(2);
      final swapped = state.swap(const PieceId(0, 0), const PieceId(1, 0));
      expect(detector.isSolved(swapped), isFalse);
    });

    test('swapping piece (0,0) and (1,1)', () {
      final state = _solvedState(2);
      final swapped = state.swap(const PieceId(0, 0), const PieceId(1, 1));
      expect(detector.isSolved(swapped), isFalse);
    });

    test('swapping piece (0,1) and (1,0)', () {
      final state = _solvedState(2);
      final swapped = state.swap(const PieceId(0, 1), const PieceId(1, 0));
      expect(detector.isSolved(swapped), isFalse);
    });

    test('swapping piece (0,1) and (1,1)', () {
      final state = _solvedState(2);
      final swapped = state.swap(const PieceId(0, 1), const PieceId(1, 1));
      expect(detector.isSolved(swapped), isFalse);
    });

    test('swapping piece (1,0) and (1,1)', () {
      final state = _solvedState(2);
      final swapped = state.swap(const PieceId(1, 0), const PieceId(1, 1));
      expect(detector.isSolved(swapped), isFalse);
    });
  });

  group('WinDetectorImpl — swapping any single pair returns false (3×3)', () {
    // Generate all unique pairs from a 3×3 grid and verify each swap breaks solved state
    final ids3x3 = [
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 3; c++) PieceId(r, c),
    ];

    for (var i = 0; i < ids3x3.length; i++) {
      for (var j = i + 1; j < ids3x3.length; j++) {
        final a = ids3x3[i];
        final b = ids3x3[j];
        test('swapping (${a.row},${a.col}) and (${b.row},${b.col})', () {
          final state = _solvedState(3);
          final swapped = state.swap(a, b);
          expect(detector.isSolved(swapped), isFalse);
        });
      }
    }
  });

  group('WinDetectorImpl — single off-by-one placement returns false', () {
    test('2×2: piece (0,0) placed at (0,1), rest correct', () {
      final pieces = _makePieces(2);
      final placement = <PieceId, BoardPosition>{
        for (final p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
      };
      // Shift piece (0,0) one column to the right, and (0,1) takes (0,0)'s spot
      placement[const PieceId(0, 0)] = const BoardPosition(0, 1);
      placement[const PieceId(0, 1)] = const BoardPosition(0, 0);
      final state = PuzzleState(
        gridSize: 2,
        sourceAspectRatio: 1.0,
        pieces: pieces,
        placement: placement,
      );
      expect(detector.isSolved(state), isFalse);
    });

    test('3×3: piece (1,1) placed at (1,2), rest adjusted', () {
      final pieces = _makePieces(3);
      final placement = <PieceId, BoardPosition>{
        for (final p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
      };
      // Swap (1,1) and (1,2) — off-by-one column for center piece
      placement[const PieceId(1, 1)] = const BoardPosition(1, 2);
      placement[const PieceId(1, 2)] = const BoardPosition(1, 1);
      final state = PuzzleState(
        gridSize: 3,
        sourceAspectRatio: 1.0,
        pieces: pieces,
        placement: placement,
      );
      expect(detector.isSolved(state), isFalse);
    });

    test('3×3: piece (0,0) placed at (1,0), rest adjusted', () {
      final pieces = _makePieces(3);
      final placement = <PieceId, BoardPosition>{
        for (final p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
      };
      // Swap (0,0) and (1,0) — off-by-one row
      placement[const PieceId(0, 0)] = const BoardPosition(1, 0);
      placement[const PieceId(1, 0)] = const BoardPosition(0, 0);
      final state = PuzzleState(
        gridSize: 3,
        sourceAspectRatio: 1.0,
        pieces: pieces,
        placement: placement,
      );
      expect(detector.isSolved(state), isFalse);
    });
  });
}
