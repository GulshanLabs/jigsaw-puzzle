import 'dart:ui';

/// Utility for computing WCAG 2.1 contrast ratios between colors.
///
/// Uses the relative luminance formula from WCAG 2.1 to determine whether
/// color pairs provide sufficient contrast for readability.
class ContrastCalculator {
  ContrastCalculator._(); // prevent instantiation

  /// Computes the WCAG 2.1 relative luminance contrast ratio between [a] and [b].
  ///
  /// The formula is `(L1 + 0.05) / (L2 + 0.05)` where L1 is the relative
  /// luminance of the lighter color and L2 is the relative luminance of the
  /// darker color.
  ///
  /// Returns a value in the range [1.0, 21.0]. A ratio of 1.0 means the
  /// colors are identical; 21.0 is the maximum contrast (black vs white).
  static double contrastRatio(Color a, Color b) {
    final luminanceA = a.computeLuminance();
    final luminanceB = b.computeLuminance();

    final double lighter;
    final double darker;

    if (luminanceA >= luminanceB) {
      lighter = luminanceA;
      darker = luminanceB;
    } else {
      lighter = luminanceB;
      darker = luminanceA;
    }

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns `true` if the contrast ratio between [foreground] and [background]
  /// meets WCAG AA requirements (>= 4.5:1 for normal text).
  static bool meetsWcagAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }
}
