import 'dart:typed_data';

import 'package:glados/glados.dart';
import 'package:image/image.dart' as img;
import 'package:jigsaw_puzzle_game/domain/image_processor.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';

/// Generates a random valid PNG image with dimensions between 12 and 212.
Generator<Uint8List> _randomImageBytes() {
  return any.combine3(
    any.intInRange(12, 212),
    any.intInRange(12, 212),
    any.int,
    (int width, int height, int seed) {
      final rng = Random(seed);
      final image = img.Image(width: width, height: height);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          image.setPixelRgba(
            x,
            y,
            rng.nextInt(256),
            rng.nextInt(256),
            rng.nextInt(256),
            255,
          );
        }
      }
      return Uint8List.fromList(img.encodePng(image));
    },
  );
}

/// Generates a grid size N in {2, 3, 4, 5, 6}.
Generator<int> _gridSize() => any.choose([2, 3, 4, 5, 6]);

void main() {
  /// **Validates: Requirements 5.2**
  ///
  /// Property 1: Image slicing produces exactly N×N pieces.
  /// For any valid image bytes and N in {2,3,4,5,6}, the ImageProcessor
  /// produces exactly N*N pieces, and all pieces have identical pixel
  /// dimensions.
  Glados2(
    _randomImageBytes(),
    _gridSize(),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 1: Image slicing produces exactly N×N pieces',
    (Uint8List imageBytes, int n) {
      final processor = ImageProcessorImpl();
      final pieces = processor.process(imageBytes, n);

      // Assert exactly N*N pieces
      expect(pieces.length, equals(n * n));

      // Decode all pieces and assert identical dimensions
      final decodedPieces =
          pieces.map((p) => img.decodePng(p.imageBytes)!).toList();
      final firstWidth = decodedPieces.first.width;
      final firstHeight = decodedPieces.first.height;

      for (final decoded in decodedPieces) {
        expect(decoded.width, equals(firstWidth));
        expect(decoded.height, equals(firstHeight));
      }
    },
    tags: 'property-test',
  );

  /// **Validates: Requirements 5.3**
  ///
  /// Property 2: Piece identifiers cover the full grid.
  /// For any valid image and N in {2,3,4,5,6}, the set of PieceIds returned
  /// equals {(r,c) | 0 ≤ r < N, 0 ≤ c < N} with no duplicates.
  Glados2(
    _randomImageBytes(),
    _gridSize(),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 2: Piece identifiers cover the full grid',
    (Uint8List imageBytes, int n) {
      final processor = ImageProcessorImpl();
      final pieces = processor.process(imageBytes, n);

      // Build the expected full grid set
      final expectedIds = <PieceId>{
        for (var r = 0; r < n; r++)
          for (var c = 0; c < n; c++) PieceId(r, c),
      };

      // Collect actual PieceIds
      final actualIds = pieces.map((p) => p.id).toList();

      // Assert no duplicates
      expect(actualIds.toSet().length, equals(actualIds.length));

      // Assert the set of PieceIds equals the expected full grid
      expect(actualIds.toSet(), equals(expectedIds));
    },
    tags: 'property-test',
  );

  /// **Validates: Requirements 1.1, 1.2, 6.1, 6.2**
  ///
  /// Property 7: Piece image data is preserved through processing.
  /// For any source image and grid size N, reassembling all N×N pieces
  /// produced by ImageProcessor in their correct grid positions reconstructs
  /// an image pixel-equivalent to the full source image (no centre-crop).
  Glados2(
    _randomImageBytes(),
    _gridSize(),
    ExploreConfig(numRuns: 100),
  ).test(
    'Property 7: Piece image data is preserved through processing',
    (Uint8List imageBytes, int n) {
      final processor = ImageProcessorImpl();
      final pieces = processor.process(imageBytes, n);

      // Decode the full source image (no centre-crop)
      final decoded = img.decodeImage(imageBytes)!;

      // Compute piece dimensions (same integer division as the processor)
      final pieceWidth = decoded.width ~/ n;
      final pieceHeight = decoded.height ~/ n;

      // The effective region covered by the pieces (may be slightly smaller
      // than the full image due to integer division truncation)
      final effectiveWidth = pieceWidth * n;
      final effectiveHeight = pieceHeight * n;

      // Reassemble pieces into a single image
      final reassembled =
          img.Image(width: effectiveWidth, height: effectiveHeight);
      for (final piece in pieces) {
        final pieceImage = img.decodePng(piece.imageBytes)!;
        final originX = piece.id.col * pieceWidth;
        final originY = piece.id.row * pieceHeight;
        for (var y = 0; y < pieceImage.height; y++) {
          for (var x = 0; x < pieceImage.width; x++) {
            reassembled.setPixel(
                originX + x, originY + y, pieceImage.getPixel(x, y));
          }
        }
      }

      // Compare pixel-by-pixel against the effective region of the full source
      for (var y = 0; y < effectiveHeight; y++) {
        for (var x = 0; x < effectiveWidth; x++) {
          final expected = decoded.getPixel(x, y);
          final actual = reassembled.getPixel(x, y);
          expect(actual, equals(expected),
              reason: 'Pixel mismatch at ($x, $y)');
        }
      }
    },
    tags: 'property-test',
  );
}
