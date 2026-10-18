import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:jigsaw_puzzle_game/domain/exceptions.dart';
import 'package:jigsaw_puzzle_game/domain/image_processor.dart';

/// Helper: creates a PNG-encoded image of the given dimensions with random pixels.
Uint8List _createTestImage(int width, int height, {int seed = 42}) {
  final rng = Random(seed);
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgba(x, y, rng.nextInt(256), rng.nextInt(256),
          rng.nextInt(256), 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  late ImageProcessorImpl processor;

  setUp(() {
    processor = ImageProcessorImpl();
  });

  // --- Piece count per grid size (Requirements 5.2) ---

  group('Piece count for each grid size', () {
    final squareImage = _createTestImage(120, 120);

    for (final n in [2, 3, 4, 5, 6]) {
      test('grid size $n produces ${n * n} pieces', () {
        final pieces = processor.process(squareImage, n);
        expect(pieces.length, equals(n * n));
      });
    }
  });

  // --- Error handling (Requirement 5.5) ---

  group('ImageProcessingException on invalid input', () {
    test('throws on corrupt (random non-image) bytes', () {
      final corrupt = Uint8List.fromList(
          List.generate(256, (i) => (i * 37 + 13) % 256));
      expect(
        () => processor.process(corrupt, 3),
        throwsA(isA<ImageProcessingException>()),
      );
    });

    test('throws on empty bytes', () {
      final empty = Uint8List(0);
      expect(
        () => processor.process(empty, 3),
        throwsA(isA<ImageProcessingException>()),
      );
    });
  });

  // --- Full-image slicing (no centre-crop) ---

  group('Full-image slicing', () {
    test('landscape image produces rectangular pieces (width > height)', () {
      // 200 wide × 100 tall with n=2 → pieces should be 100×50
      final landscape = _createTestImage(200, 100);
      final pieces = processor.process(landscape, 2);

      expect(pieces.length, equals(4));
      final decoded = img.decodePng(pieces.first.imageBytes)!;
      expect(decoded.width, equals(100));
      expect(decoded.height, equals(50));
    });

    test('portrait image produces rectangular pieces (height > width)', () {
      // 80 wide × 160 tall with n=2 → pieces should be 40×80
      final portrait = _createTestImage(80, 160);
      final pieces = processor.process(portrait, 2);

      expect(pieces.length, equals(4));
      final decoded = img.decodePng(pieces.first.imageBytes)!;
      expect(decoded.width, equals(40));
      expect(decoded.height, equals(80));
    });

    test('square image produces square pieces', () {
      final square = _createTestImage(120, 120);
      final pieces = processor.process(square, 3);

      expect(pieces.length, equals(9));
      final decoded = img.decodePng(pieces.first.imageBytes)!;
      expect(decoded.width, equals(40));
      expect(decoded.height, equals(40));
    });
  });

  // --- Minimum dimension validation ---

  group('ImageProcessingException on image too small for grid', () {
    test('throws when width < N', () {
      final tooNarrow = _createTestImage(2, 100);
      expect(
        () => processor.process(tooNarrow, 3),
        throwsA(isA<ImageProcessingException>()),
      );
    });

    test('throws when height < N', () {
      final tooShort = _createTestImage(100, 2);
      expect(
        () => processor.process(tooShort, 3),
        throwsA(isA<ImageProcessingException>()),
      );
    });
  });
}
