// Procedurally synthesized calm, natural sounds for Tile Solitaire.
// Bamboo knocks, soft chimes, sand swishes, ambient garden music loops.
// All generated in code as 16-bit PCM WAV bytes - no audio assets.
import 'dart:math';
import 'dart:typed_data';

const int kSampleRate = 22050;

Uint8List _encodeWav(List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void writeAscii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, kSampleRate, Endian.little);
  data.setUint32(28, kSampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  writeAscii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = samples[i].clamp(-1.0, 1.0);
    data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

/// Render [seconds] of audio. [fn] receives (timeSeconds, whiteNoise).
Uint8List _render(double seconds, double Function(double t, double n) fn) {
  final count = (seconds * kSampleRate).round();
  final rng = Random(1234567);
  final samples = List<double>.filled(count, 0.0);
  var peak = 0.0;
  for (var i = 0; i < count; i++) {
    final v = fn(i / kSampleRate, rng.nextDouble() * 2 - 1);
    samples[i] = v;
    final a = v.abs();
    if (a > peak) peak = a;
  }
  if (peak > 0) {
    final g = 0.89 / peak;
    for (var i = 0; i < count; i++) {
      samples[i] *= g;
    }
  }
  return _encodeWav(samples);
}

/// Wooden knock: body resonance + a breath of stick noise.
double _knock(double t, double freq, double noise) {
  if (t < 0) return 0;
  return sin(2 * pi * freq * t) * exp(-34 * t) +
      0.45 * sin(2 * pi * freq * 2 * t) * exp(-52 * t) +
      noise * 0.35 * exp(-110 * t);
}

/// Soft bell/chime with inharmonic shimmer.
double _chime(double t, double freq) {
  if (t < 0) return 0;
  return sin(2 * pi * freq * t) * exp(-4.6 * t) +
      0.35 * sin(2 * pi * freq * 2.01 * t) * exp(-7.5 * t) +
      0.12 * sin(2 * pi * freq * 2.98 * t) * exp(-11 * t);
}

/// Koto-like pluck for the music loops.
double _pluck(double t, double start, double freq) {
  final dt = t - start;
  if (dt < 0 || dt > 2.4) return 0;
  return (sin(2 * pi * freq * dt) * exp(-4.2 * dt) +
          0.3 * sin(2 * pi * freq * 2 * dt) * exp(-6.5 * dt)) *
      0.5;
}

class ZenSounds {
  /// Button press / generic tap.
  static Uint8List tap() =>
      _render(0.14, (t, n) => _knock(t, 250, n) * 0.7);

  /// Selecting a tile: a slightly higher bamboo tick.
  static Uint8List select() =>
      _render(0.12, (t, n) => _knock(t, 330, n) * 0.7);

  /// Pair matched: two knocks blooming into a soft chime.
  static Uint8List match() => _render(1.0, (t, n) {
        var v = _knock(t, 240, n) * 0.7 + _knock(t - 0.08, 300, n) * 0.7;
        v += _chime(t - 0.16, 660) * 0.55 + _chime(t - 0.24, 880) * 0.4;
        return v;
      });

  /// Invalid move: low wooden thud.
  static Uint8List invalid() =>
      _render(0.22, (t, n) => _knock(t, 105, n) * 0.9);

  /// Shuffle: sand swishing through a rake.
  static Uint8List shuffle() => _render(0.55, (t, n) {
        final env = sin(pi * (t / 0.55)).clamp(0.0, 1.0);
        // crude lowpass: soften the noise with a slow wobble
        final soft = n * 0.5 + 0.5 * sin(2 * pi * 900 * t) * n.abs();
        return soft * env * env * 0.5;
      });

  /// Hint: a single gentle chime.
  static Uint8List hint() => _render(0.8, (t, n) => _chime(t, 587.33) * 0.7);

  /// Undo: two descending soft knocks.
  static Uint8List undo() => _render(0.4, (t, n) {
        return _knock(t, 220, n) * 0.6 + _knock(t - 0.12, 175, n) * 0.6;
      });

  /// Game start: warm welcoming chime.
  static Uint8List gameStart() => _render(1.2, (t, n) {
        return _chime(t, 440) * 0.6 + _chime(t - 0.18, 659.25) * 0.5;
      });

  /// Win: rising pentatonic garden bells.
  static Uint8List win() {
    const notes = [440.0, 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5];
    return _render(2.8, (t, n) {
      var v = 0.0;
      for (var i = 0; i < notes.length; i++) {
        v += _chime(t - i * 0.17, notes[i]) * 0.5;
      }
      return v;
    });
  }

  /// Lose: soft descending tones, still calm.
  static Uint8List lose() => _render(1.8, (t, n) {
        return _chime(t, 329.63) * 0.5 +
            _chime(t - 0.3, 261.63) * 0.5 +
            _chime(t - 0.6, 220.0) * 0.55;
      });

  static double _drone(double t, double period) {
    final swell = 0.7 + 0.3 * sin(2 * pi * 3 * t / period);
    final swell2 = 0.7 + 0.3 * sin(2 * pi * 2 * t / period + 1.3);
    // Partials of 55 Hz: every partial completes an integer number of
    // cycles over [period], so the loop is seamless.
    return 0.16 * swell * sin(2 * pi * 55 * t) +
        0.10 * swell * sin(2 * pi * 110 * t + 0.7) +
        0.06 * swell2 * sin(2 * pi * 165 * t + 1.1) +
        0.04 * sin(2 * pi * 220 * t + 2.0);
  }

  /// 16 s seamless ambient loop for the main menu.
  static Uint8List musicMenu() {
    const period = 16.0;
    const plucks = [
      [1.2, 440.0],
      [4.1, 523.25],
      [7.3, 392.0],
      [10.2, 587.33],
      [12.8, 440.0],
    ];
    return _render(period, (t, n) {
      var v = _drone(t, period);
      v += 0.012 * n * (0.6 + 0.4 * sin(2 * pi * 2 * t / period));
      for (final p in plucks) {
        v += _pluck(t, p[0], p[1]) * 0.5;
      }
      return v * 0.55;
    });
  }

  /// 16 s seamless ambient loop for gameplay (a touch more movement).
  static Uint8List musicGame() {
    const period = 16.0;
    const plucks = [
      [0.8, 392.0],
      [2.6, 523.25],
      [4.4, 440.0],
      [6.5, 659.25],
      [8.4, 587.33],
      [10.6, 523.25],
      [12.4, 783.99],
      [14.0, 659.25],
    ];
    return _render(period, (t, n) {
      var v = _drone(t, period);
      v += 0.10 *
          (0.6 + 0.4 * sin(2 * pi * 5 * t / period + 0.5)) *
          sin(2 * pi * 82.5 * t);
      v += 0.012 * n * (0.6 + 0.4 * sin(2 * pi * 2 * t / period));
      for (final p in plucks) {
        v += _pluck(t, p[0], p[1]) * 0.45;
      }
      return v * 0.55;
    });
  }
}
