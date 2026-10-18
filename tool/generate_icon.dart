import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Generates a 1024×1024 app icon with a colorful 3×3 puzzle grid design.
void main() {
  const size = 1024;
  const n = 3;
  const padding = 80;
  const gap = 12;
  const cornerRadius = 40;

  final image = img.Image(width: size, height: size);

  // Fill background with a deep purple gradient
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final t = y / size;
      final r = (40 + (80 - 40) * t).round();
      final g = (20 + (40 - 20) * t).round();
      final b = (120 + (180 - 120) * t).round();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Puzzle piece colors — vibrant and distinct
  final colors = [
    [255, 87, 87],   // coral red
    [255, 165, 50],  // orange
    [255, 220, 60],  // yellow
    [80, 200, 120],  // green
    [60, 180, 220],  // sky blue
    [100, 120, 255], // blue
    [180, 100, 255], // purple
    [255, 100, 180], // pink
    [120, 220, 200], // teal
  ];

  final gridSize = size - 2 * padding;
  final cellSize = (gridSize - (n - 1) * gap) ~/ n;

  for (var row = 0; row < n; row++) {
    for (var col = 0; col < n; col++) {
      final colorIdx = row * n + col;
      final c = colors[colorIdx];

      final x0 = padding + col * (cellSize + gap);
      final y0 = padding + row * (cellSize + gap);

      // Draw rounded rectangle for each piece
      _drawRoundedRect(image, x0, y0, cellSize, cellSize, 24, c[0], c[1], c[2]);

      // Add a subtle inner highlight (lighter shade at top)
      for (var dy = 0; dy < cellSize ~/ 3; dy++) {
        for (var dx = 0; dx < cellSize; dx++) {
          final px = x0 + dx;
          final py = y0 + dy;
          if (px >= 0 && px < size && py >= 0 && py < size) {
            if (_isInsideRoundedRect(dx, dy, cellSize, cellSize, 24)) {
              final alpha = ((1.0 - dy / (cellSize / 3)) * 40).round();
              final existing = image.getPixel(px, py);
              final er = existing.r.toInt();
              final eg = existing.g.toInt();
              final eb = existing.b.toInt();
              final nr = min(255, er + alpha);
              final ng = min(255, eg + alpha);
              final nb = min(255, eb + alpha);
              image.setPixelRgba(px, py, nr, ng, nb, 255);
            }
          }
        }
      }
    }
  }

  // Offset one piece slightly to suggest a puzzle being assembled
  // Draw a small shadow/offset effect on the center piece
  final centerX = padding + 1 * (cellSize + gap);
  final centerY = padding + 1 * (cellSize + gap);
  // Add a subtle shadow below-right of center piece
  for (var dy = 0; dy < cellSize; dy++) {
    for (var dx = 0; dx < cellSize; dx++) {
      if (_isInsideRoundedRect(dx, dy, cellSize, cellSize, 24)) {
        final sx = centerX + dx + 6;
        final sy = centerY + dy + 6;
        if (sx >= 0 && sx < size && sy >= 0 && sy < size) {
          final existing = image.getPixel(sx, sy);
          final er = existing.r.toInt();
          final eg = existing.g.toInt();
          final eb = existing.b.toInt();
          // Only darken background pixels, not other pieces
          if (!_isPartOfAnyPiece(sx, sy, padding, cellSize, gap, n)) {
            image.setPixelRgba(sx, sy, (er * 0.6).round(), (eg * 0.6).round(), (eb * 0.6).round(), 255);
          }
        }
      }
    }
  }

  // Save the icon
  final outputDir = Directory('assets');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);
  File('assets/app_icon.png').writeAsBytesSync(img.encodePng(image));
  print('Icon generated at assets/app_icon.png');
}

bool _isPartOfAnyPiece(int px, int py, int padding, int cellSize, int gap, int n) {
  for (var row = 0; row < n; row++) {
    for (var col = 0; col < n; col++) {
      final x0 = padding + col * (cellSize + gap);
      final y0 = padding + row * (cellSize + gap);
      if (px >= x0 && px < x0 + cellSize && py >= y0 && py < y0 + cellSize) {
        return true;
      }
    }
  }
  return false;
}

void _drawRoundedRect(img.Image image, int x0, int y0, int w, int h, int radius, int r, int g, int b) {
  for (var dy = 0; dy < h; dy++) {
    for (var dx = 0; dx < w; dx++) {
      if (_isInsideRoundedRect(dx, dy, w, h, radius)) {
        final px = x0 + dx;
        final py = y0 + dy;
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          image.setPixelRgba(px, py, r, g, b, 255);
        }
      }
    }
  }
}

bool _isInsideRoundedRect(int dx, int dy, int w, int h, int radius) {
  // Check corners
  if (dx < radius && dy < radius) {
    return (dx - radius) * (dx - radius) + (dy - radius) * (dy - radius) <= radius * radius;
  }
  if (dx >= w - radius && dy < radius) {
    return (dx - (w - radius - 1)) * (dx - (w - radius - 1)) + (dy - radius) * (dy - radius) <= radius * radius;
  }
  if (dx < radius && dy >= h - radius) {
    return (dx - radius) * (dx - radius) + (dy - (h - radius - 1)) * (dy - (h - radius - 1)) <= radius * radius;
  }
  if (dx >= w - radius && dy >= h - radius) {
    return (dx - (w - radius - 1)) * (dx - (w - radius - 1)) + (dy - (h - radius - 1)) * (dy - (h - radius - 1)) <= radius * radius;
  }
  return true;
}
