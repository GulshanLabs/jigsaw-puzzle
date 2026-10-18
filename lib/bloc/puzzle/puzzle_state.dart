import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';

/// Base class for all puzzle BLoC states.
abstract class PuzzleBlocState extends Equatable {
  const PuzzleBlocState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no photo selected yet.
class PuzzleInitial extends PuzzleBlocState {
  const PuzzleInitial();
}

/// Permission was denied for the requested photo source.
class PermissionDenied extends PuzzleBlocState {
  final PhotoSource source;
  final bool isPermanent;

  const PermissionDenied({required this.source, required this.isPermanent});

  @override
  List<Object?> get props => [source, isPermanent];
}

/// A photo has been acquired from camera or gallery.
class PhotoAcquired extends PuzzleBlocState {
  final Uint8List imageBytes;

  const PhotoAcquired(this.imageBytes);

  @override
  List<Object?> get props => [imageBytes];
}

/// User is configuring the grid size.
class ConfiguringGrid extends PuzzleBlocState {
  final Uint8List imageBytes;
  final int? selectedN;

  const ConfiguringGrid({
    required this.imageBytes,
    this.selectedN,
  });

  @override
  List<Object?> get props => [imageBytes, selectedN];
}

/// Image is being processed (slicing into pieces).
class ProcessingImage extends PuzzleBlocState {
  final Uint8List imageBytes;
  final int gridSize;

  const ProcessingImage({
    required this.imageBytes,
    required this.gridSize,
  });

  @override
  List<Object?> get props => [imageBytes, gridSize];
}

/// The puzzle board is active and the user is solving.
class BoardActive extends PuzzleBlocState {
  final PuzzleState state;
  final PieceId? selectedPieceId;

  const BoardActive({required this.state, this.selectedPieceId});

  @override
  List<Object?> get props => [state, selectedPieceId];
}

/// The puzzle has been solved.
class PuzzleSolved extends PuzzleBlocState {
  final PuzzleState state;
  final int moveCount;
  final int elapsedSeconds;

  const PuzzleSolved({
    required this.state,
    required this.moveCount,
    required this.elapsedSeconds,
  });

  @override
  List<Object?> get props => [state, moveCount, elapsedSeconds];
}

/// An error occurred during image processing.
class ImageProcessingError extends PuzzleBlocState {
  const ImageProcessingError();
}
