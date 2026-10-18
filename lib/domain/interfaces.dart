import 'dart:typed_data';

import 'package:jigsaw_puzzle_game/domain/models.dart';

/// Wraps OS-level permission requests.
abstract class PermissionService {
  Future<PermissionStatus> requestCameraPermission();
  Future<PermissionStatus> requestGalleryPermission();
  Future<void> openAppSettings();
}

/// Wraps the image picker plugin. Returns raw image bytes or null on cancellation.
abstract class ImagePickerService {
  Future<Uint8List?> pickFromCamera();
  Future<Uint8List?> pickFromGallery();
}

/// Splits the full source image into N×N equal rectangular pieces.
abstract class ImageProcessor {
  /// Splits [imageBytes] into exactly n*n pieces with PieceId identifiers.
  /// Throws [ImageProcessingException] on failure or if image is too small.
  List<Piece> process(Uint8List imageBytes, int n);
}

/// Randomises piece positions, guaranteeing the result is not the solved state.
abstract class ShuffleEngine {
  /// Returns a shuffled copy of [pieces].
  /// Guarantees result != solved order.
  List<Piece> shuffle(List<Piece> pieces);
}

/// Compares current board positions to correct positions.
abstract class WinDetector {
  /// Returns true iff every piece's boardPosition == its correctPosition.
  bool isSolved(PuzzleState state);
}
