import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// The user's own permission status (not from permission_handler).
enum PermissionStatus { granted, denied, permanentlyDenied }

/// Source of the photo for the puzzle.
enum PhotoSource { camera, gallery }

/// Uniquely identifies a puzzle piece by its grid row and column.
class PieceId extends Equatable {
  final int row;
  final int col;
  const PieceId(this.row, this.col);
  @override
  List<Object?> get props => [row, col];
  @override
  String toString() => 'PieceId($row, $col)';
}

/// A single puzzle piece containing its identity and cropped image data.
class Piece extends Equatable {
  final PieceId id;
  final Uint8List imageBytes;

  const Piece({required this.id, required this.imageBytes});

  @override
  List<Object?> get props => [id, imageBytes];

  @override
  String toString() => 'Piece(id: $id)';
}

/// A position on the puzzle board.
class BoardPosition extends Equatable {
  final int row;
  final int col;

  const BoardPosition(this.row, this.col);

  @override
  List<Object?> get props => [row, col];

  @override
  String toString() => 'BoardPosition($row, $col)';
}

/// The current state of the puzzle board.
class PuzzleState extends Equatable {
  final int gridSize;
  final double sourceAspectRatio;
  final List<Piece> pieces;
  final Map<PieceId, BoardPosition> placement;
  final int moveCount;

  const PuzzleState({
    required this.gridSize,
    required this.sourceAspectRatio,
    required this.pieces,
    required this.placement,
    this.moveCount = 0,
  });

  /// Returns true iff every piece is in its correct position.
  bool get isSolved => pieces.every(
    (p) => placement[p.id] == BoardPosition(p.id.row, p.id.col),
  );

  /// Returns a new PuzzleState with pieces [a] and [b] swapped,
  /// and moveCount incremented by 1.
  PuzzleState swap(PieceId a, PieceId b) {
    final newPlacement = Map<PieceId, BoardPosition>.from(placement);
    final posA = newPlacement[a]!;
    final posB = newPlacement[b]!;
    newPlacement[a] = posB;
    newPlacement[b] = posA;
    return PuzzleState(
      gridSize: gridSize,
      sourceAspectRatio: sourceAspectRatio,
      pieces: pieces,
      placement: newPlacement,
      moveCount: moveCount + 1,
    );
  }

  @override
  List<Object?> get props => [gridSize, sourceAspectRatio, pieces, placement, moveCount];

  @override
  String toString() =>
      'PuzzleState(gridSize: $gridSize, moveCount: $moveCount, isSolved: $isSolved)';
}
