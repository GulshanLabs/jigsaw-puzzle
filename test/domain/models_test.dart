import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';

void main() {
  group('PieceId', () {
    test('equality works via Equatable', () {
      expect(const PieceId(0, 1), equals(const PieceId(0, 1)));
      expect(const PieceId(0, 1), isNot(equals(const PieceId(1, 0))));
    });
  });

  group('BoardPosition', () {
    test('equality works via Equatable', () {
      expect(const BoardPosition(2, 3), equals(const BoardPosition(2, 3)));
      expect(
        const BoardPosition(2, 3),
        isNot(equals(const BoardPosition(3, 2))),
      );
    });
  });

  group('Piece', () {
    test('equality works via Equatable', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final p1 = Piece(id: const PieceId(0, 0), imageBytes: bytes);
      final p2 = Piece(id: const PieceId(0, 0), imageBytes: bytes);
      expect(p1, equals(p2));
    });
  });

  group('PuzzleState', () {
    late List<Piece> pieces;
    late Map<PieceId, BoardPosition> solvedPlacement;
    late PuzzleState solvedState;

    setUp(() {
      // Create a simple 2x2 puzzle
      pieces = [
        for (int r = 0; r < 2; r++)
          for (int c = 0; c < 2; c++)
            Piece(
              id: PieceId(r, c),
              imageBytes: Uint8List.fromList([r, c]),
            ),
      ];
      solvedPlacement = {
        for (final p in pieces) p.id: BoardPosition(p.id.row, p.id.col),
      };
      solvedState = PuzzleState(
        gridSize: 2,
        sourceAspectRatio: 1.0,
        pieces: pieces,
        placement: solvedPlacement,
      );
    });

    group('isSolved', () {
      test('returns true when all pieces are in correct positions', () {
        expect(solvedState.isSolved, isTrue);
      });

      test('returns false when any piece is out of position', () {
        // Swap (0,0) and (0,1)
        final swappedPlacement = Map<PieceId, BoardPosition>.from(
          solvedPlacement,
        );
        swappedPlacement[const PieceId(0, 0)] = const BoardPosition(0, 1);
        swappedPlacement[const PieceId(0, 1)] = const BoardPosition(0, 0);

        final state = PuzzleState(
          gridSize: 2,
          sourceAspectRatio: 1.0,
          pieces: pieces,
          placement: swappedPlacement,
        );
        expect(state.isSolved, isFalse);
      });
    });

    group('swap', () {
      test('swaps board positions of two pieces', () {
        final a = const PieceId(0, 0);
        final b = const PieceId(1, 1);

        final swapped = solvedState.swap(a, b);

        expect(swapped.placement[a], equals(const BoardPosition(1, 1)));
        expect(swapped.placement[b], equals(const BoardPosition(0, 0)));
      });

      test('increments moveCount by 1', () {
        final a = const PieceId(0, 0);
        final b = const PieceId(0, 1);

        final swapped = solvedState.swap(a, b);
        expect(swapped.moveCount, equals(1));

        final swappedAgain = swapped.swap(a, b);
        expect(swappedAgain.moveCount, equals(2));
      });

      test('does not mutate the original state', () {
        final a = const PieceId(0, 0);
        final b = const PieceId(0, 1);

        final originalMoveCount = solvedState.moveCount;
        final originalPlacement = Map<PieceId, BoardPosition>.from(
          solvedState.placement,
        );

        solvedState.swap(a, b);

        expect(solvedState.moveCount, equals(originalMoveCount));
        expect(solvedState.placement, equals(originalPlacement));
      });

      test('swap is its own inverse (round-trip)', () {
        final a = const PieceId(0, 0);
        final b = const PieceId(1, 0);

        final swapped = solvedState.swap(a, b);
        final roundTripped = swapped.swap(a, b);

        // Placement should be back to original
        expect(roundTripped.placement, equals(solvedState.placement));
        // But moveCount should be incremented twice
        expect(roundTripped.moveCount, equals(2));
      });

      test('preserves gridSize and pieces', () {
        final a = const PieceId(0, 0);
        final b = const PieceId(0, 1);

        final swapped = solvedState.swap(a, b);
        expect(swapped.gridSize, equals(solvedState.gridSize));
        expect(swapped.pieces, equals(solvedState.pieces));
      });
    });
  });

  group('PhotoSource', () {
    test('has camera and gallery values', () {
      expect(PhotoSource.values, contains(PhotoSource.camera));
      expect(PhotoSource.values, contains(PhotoSource.gallery));
      expect(PhotoSource.values.length, equals(2));
    });
  });

  group('PermissionStatus', () {
    test('has granted, denied, and permanentlyDenied values', () {
      expect(PermissionStatus.values, contains(PermissionStatus.granted));
      expect(PermissionStatus.values, contains(PermissionStatus.denied));
      expect(
        PermissionStatus.values,
        contains(PermissionStatus.permanentlyDenied),
      );
      expect(PermissionStatus.values.length, equals(3));
    });
  });
}
