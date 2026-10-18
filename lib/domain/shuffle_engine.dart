import 'dart:math';

import 'package:jigsaw_puzzle_game/domain/interfaces.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';

/// Concrete implementation of [ShuffleEngine].
///
/// Randomises piece positions using Fisher-Yates shuffle.
/// Re-shuffles up to [_maxRetries] times if the result equals the solved
/// state. Falls back to a deterministic offset shuffle if all retries
/// still produce the solved arrangement.
class ShuffleEngineImpl implements ShuffleEngine {
  static const int _maxRetries = 10;

  final Random _random;

  /// Creates a [ShuffleEngineImpl].
  ///
  /// An optional [random] parameter can be supplied for deterministic
  /// testing; otherwise a default [Random] instance is used.
  ShuffleEngineImpl({Random? random}) : _random = random ?? Random();

  @override
  List<Piece> shuffle(List<Piece> pieces) {
    if (pieces.length <= 1) {
      // A single piece (or empty list) is always "solved" — apply
      // deterministic offset directly since random shuffle cannot help.
      return List<Piece>.unmodifiable(pieces);
    }

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final shuffled = _randomShuffle(pieces);
      if (!_isSolvedOrder(shuffled)) {
        return shuffled;
      }
    }

    // All random attempts produced the solved state — use deterministic
    // offset shuffle (rotate by 1 position).
    return _deterministicOffsetShuffle(pieces);
  }

  /// Returns a new list with elements randomly reordered (Fisher-Yates).
  List<Piece> _randomShuffle(List<Piece> pieces) {
    final result = List<Piece>.from(pieces);
    for (var i = result.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return result;
  }

  /// Checks whether [pieces] are in solved order by comparing each piece's
  /// index against its expected grid position.
  bool _isSolvedOrder(List<Piece> pieces) {
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

  /// Deterministic fallback: rotate the list by 1 position.
  /// This guarantees the result differs from solved order for any
  /// list with more than 1 element.
  List<Piece> _deterministicOffsetShuffle(List<Piece> pieces) {
    final result = <Piece>[
      pieces.last,
      ...pieces.sublist(0, pieces.length - 1),
    ];
    return result;
  }
}
