import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:jigsaw_puzzle_game/domain/exceptions.dart';
import 'package:jigsaw_puzzle_game/domain/interfaces.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';

/// Concrete implementation of [ImageProcessor].
///
/// Uses the `image` package to decode raw bytes and slice the full image
/// into N×N equal rectangular pieces.
class ImageProcessorImpl implements ImageProcessor {
  @override
  List<Piece> process(Uint8List imageBytes, int n) {
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        throw const ImageProcessingException(
          'Failed to decode image: unsupported or corrupt format.',
        );
      }

      _validateMinDimensions(decoded, n);

      return _slice(decoded, n);
    } on ImageProcessingException {
      rethrow;
    } catch (e) {
      throw ImageProcessingException(
        'Image processing failed: $e',
      );
    }
  }

  /// Throws [ImageProcessingException] when [image] is too small for grid size [n].
  void _validateMinDimensions(img.Image image, int n) {
    if (image.width < n || image.height < n) {
      throw ImageProcessingException(
        'Image too small (${image.width}×${image.height}) for grid size $n.',
      );
    }
  }

  /// Slices [source] into [n]×[n] equal rectangular pieces, encoding each as PNG.
  List<Piece> _slice(img.Image source, int n) {
    final pieceWidth = source.width ~/ n;
    final pieceHeight = source.height ~/ n;
    final pieces = <Piece>[];

    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final tile = img.copyCrop(
          source,
          x: col * pieceWidth,
          y: row * pieceHeight,
          width: pieceWidth,
          height: pieceHeight,
        );
        final bytes = Uint8List.fromList(img.encodePng(tile));
        pieces.add(Piece(id: PieceId(row, col), imageBytes: bytes));
      }
    }

    return pieces;
  }
}
