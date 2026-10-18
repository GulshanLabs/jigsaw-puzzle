import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:jigsaw_puzzle_game/domain/shuffle_engine.dart';

/// Helper: creates a list of N×N pieces in solved order.
List<Piece> _makePieces(int n) {
  return [
    for (var r = 0; r < n; r++)
      for (var c = 0; c < n; c++)
        Piece(id: PieceId(r, c), imageBytes: Uint8List.fromList([r, c])),
  ];
}

void main() {
  group('ShuffleEngineImpl', () {
    late ShuffleEngineImpl engine;

    setUp(() {
      engine = ShuffleEngineImpl(random: Random(42));
    });

    group('output length equals input length', () {
      for (final n in [2, 3, 4, 5, 6]) {
        test('${n}x$n grid', () {
          final pieces = _makePieces(n);
          final shuffled = engine.shuffle(pieces);
          expect(shuffled.length, equals(pieces.length));
        });
      }
    });

    group('all original pieces are present (no duplicates or drops)', () {
      for (final n in [2, 3, 4, 5, 6]) {
        test('${n}x$n grid', () {
          final pieces = _makePieces(n);
          final shuffled = engine.shuffle(pieces);

          final originalIds = pieces.map((p) => p.id).toSet();
          final shuffledIds = shuffled.map((p) => p.id).toSet();

          expect(shuffledIds, equals(originalIds));
        });
      }
    });

    group('no duplicates in shuffled result', () {
      for (final n in [2, 3, 4, 5, 6]) {
        test('${n}x$n grid', () {
          final pieces = _makePieces(n);
          final shuffled = engine.shuffle(pieces);

          final ids = shuffled.map((p) => p.id).toList();
          expect(ids.length, equals(ids.toSet().length));
        });
      }
    });

    group('input list is not mutated', () {
      for (final n in [2, 3, 4, 5, 6]) {
        test('${n}x$n grid', () {
          final pieces = _makePieces(n);
          final originalOrder =
              pieces.map((p) => p.id).toList();

          engine.shuffle(pieces);

          final afterOrder = pieces.map((p) => p.id).toList();
          expect(afterOrder, equals(originalOrder));
        });
      }
    });

    test('single piece list returns unmodified', () {
      final pieces = [
        Piece(id: const PieceId(0, 0), imageBytes: Uint8List.fromList([0])),
      ];
      final shuffled = engine.shuffle(pieces);
      expect(shuffled.length, 1);
      expect(shuffled.first.id, equals(const PieceId(0, 0)));
    });

    test('empty list returns empty', () {
      final shuffled = engine.shuffle([]);
      expect(shuffled, isEmpty);
    });
  });
}
