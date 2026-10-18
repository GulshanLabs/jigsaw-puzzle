import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;

/// Writes a valid PCM WAV header + data to a [ByteData] buffer.
Uint8List buildWav(List<double> samples) {
  final numSamples = samples.length;
  const numChannels = 1;
  const bitsPerSample = 16;
  const byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  const blockAlign = numChannels * (bitsPerSample ~/ 8);
  final dataSize = numSamples * blockAlign;
  final fileSize = 36 + dataSize;

  final buffer = ByteData(8 + fileSize);
  var offset = 0;

  // RIFF header
  for (final c in [0x52, 0x49, 0x46, 0x46]) buffer.setUint8(offset++, c);
  buffer.setUint32(offset, fileSize, Endian.little); offset += 4;
  for (final c in [0x57, 0x41, 0x56, 0x45]) buffer.setUint8(offset++, c);

  // fmt sub-chunk
  for (final c in [0x66, 0x6D, 0x74, 0x20]) buffer.setUint8(offset++, c);
  buffer.setUint32(offset, 16, Endian.little); offset += 4;
  buffer.setUint16(offset, 1, Endian.little); offset += 2;
  buffer.setUint16(offset, numChannels, Endian.little); offset += 2;
  buffer.setUint32(offset, sampleRate, Endian.little); offset += 4;
  buffer.setUint32(offset, byteRate, Endian.little); offset += 4;
  buffer.setUint16(offset, blockAlign, Endian.little); offset += 2;
  buffer.setUint16(offset, bitsPerSample, Endian.little); offset += 2;

  // data sub-chunk
  for (final c in [0x64, 0x61, 0x74, 0x61]) buffer.setUint8(offset++, c);
  buffer.setUint32(offset, dataSize, Endian.little); offset += 4;

  for (final s in samples) {
    final clamped = (s * 32767).round().clamp(-32768, 32767);
    buffer.setInt16(offset, clamped, Endian.little);
    offset += 2;
  }

  return buffer.buffer.asUint8List();
}

/// Generates a soft, satisfying "click/pop" sound for piece selection.
///
/// Based on research into puzzle game UI sounds: a short percussive click
/// with a quick attack and fast decay. Uses a mix of a brief high-frequency
/// transient (the "click") followed by a warm resonant body (the "pop").
/// Total duration ~80ms — crisp and non-intrusive.
List<double> generateTapSound() {
  const duration = 0.08; // 80ms — short and snappy
  final numSamples = (sampleRate * duration).round();
  final samples = List<double>.filled(numSamples, 0);

  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = t / duration;

    // Fast exponential decay envelope
    final envelope = exp(-progress * 12);

    // Click transient: brief high-frequency burst (3200 Hz) that decays fast
    final clickEnv = exp(-progress * 40);
    final click = sin(2 * pi * 3200 * t) * clickEnv * 0.3;

    // Pop body: warm mid-frequency tone (800 Hz) with pitch drop
    final freq = 800 - 400 * progress; // pitch drops from 800 to 400 Hz
    final body = sin(2 * pi * freq * t) * envelope * 0.5;

    // Sub thump: low-frequency punch (200 Hz)
    final subEnv = exp(-progress * 20);
    final sub = sin(2 * pi * 200 * t) * subEnv * 0.2;

    samples[i] = (click + body + sub).clamp(-1.0, 1.0);
  }

  return samples;
}

/// Generates a smooth "whoosh/slide" sound for piece swapping.
///
/// Based on research into puzzle tile swap sounds: a smooth frequency sweep
/// that conveys movement. Uses a rising-then-falling pitch sweep with
/// filtered noise for the "air" quality. Total duration ~180ms.
List<double> generateSwapSound() {
  const duration = 0.18; // 180ms
  final numSamples = (sampleRate * duration).round();
  final samples = List<double>.filled(numSamples, 0);
  final rng = Random(42); // deterministic noise

  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = t / duration;

    // Bell-shaped envelope: fade in then fade out
    final envelope = sin(pi * progress) * exp(-progress * 3);

    // Frequency sweep: rises from 400 Hz to 1200 Hz then back down
    final sweepPhase = sin(pi * progress);
    final freq = 400 + 800 * sweepPhase;
    final tonal = sin(2 * pi * freq * t) * 0.35;

    // Filtered noise for "air/whoosh" quality
    final noise = (rng.nextDouble() * 2 - 1) * 0.15;

    // Second harmonic for richness
    final harmonic = sin(2 * pi * freq * 1.5 * t) * 0.1;

    samples[i] = ((tonal + noise + harmonic) * envelope).clamp(-1.0, 1.0);
  }

  // Simple smoothing pass to reduce harshness
  for (var i = 1; i < numSamples - 1; i++) {
    samples[i] = (samples[i - 1] + samples[i] * 2 + samples[i + 1]) / 4;
  }

  return samples;
}

void main() {
  final outputDir = Directory('assets/audio');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // Tap sound: soft click/pop (~80ms)
  final tapSamples = generateTapSound();
  final tapWav = buildWav(tapSamples);
  File('assets/audio/tap_sound.wav').writeAsBytesSync(tapWav);
  print('Generated tap_sound.wav (${tapWav.length} bytes, '
      '${tapSamples.length / sampleRate * 1000}ms)');

  // Swap sound: smooth whoosh/slide (~180ms)
  final swapSamples = generateSwapSound();
  final swapWav = buildWav(swapSamples);
  File('assets/audio/swap_sound.wav').writeAsBytesSync(swapWav);
  print('Generated swap_sound.wav (${swapWav.length} bytes, '
      '${swapSamples.length / sampleRate * 1000}ms)');

  print('Done! Audio assets generated.');
}
