import 'dart:math';
import 'dart:typed_data';

/// ITU-T E.180 Special Information Tone (SIT) Tone Generator.
/// Generates three sequential tones (950 Hz, 1400 Hz, 1800 Hz) for 330ms each.
/// Autodialers detect this signal and automatically purge the number from campaign call queues.
class SitTonePlayer {
  static const int sampleRate = 44100;
  static const double toneDurationSeconds = 0.330;
  static const List<double> sitFrequencies = [950.0, 1400.0, 1800.0];

  /// Generates 16-bit PCM mono WAV audio data containing the ITU-T E.180 SIT sequence.
  static Uint8List generateSitToneWav() {
    final int samplesPerTone = (sampleRate * toneDurationSeconds).round();
    final int totalSamples = samplesPerTone * sitFrequencies.length;
    final int dataByteLength = totalSamples * 2; // 16-bit = 2 bytes per sample

    final bytes = ByteData(44 + dataByteLength);

    // RIFF Header
    _writeString(bytes, 0, 'RIFF');
    bytes.setUint32(4, 36 + dataByteLength, Endian.little);
    _writeString(bytes, 8, 'WAVE');

    // fmt chunk
    _writeString(bytes, 12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little); // Chunk size
    bytes.setUint16(20, 1, Endian.little); // PCM format
    bytes.setUint16(22, 1, Endian.little); // 1 channel (mono)
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
    bytes.setUint16(32, 2, Endian.little); // Block align
    bytes.setUint16(34, 16, Endian.little); // Bits per sample

    // data chunk
    _writeString(bytes, 36, 'data');
    bytes.setUint32(40, dataByteLength, Endian.little);

    int offset = 44;
    for (final freq in sitFrequencies) {
      for (int i = 0; i < samplesPerTone; i++) {
        final t = i / sampleRate;
        // Apply smooth envelope attack & release to avoid audio click
        double envelope = 1.0;
        if (i < 200) envelope = i / 200.0;
        if (i > samplesPerTone - 200) envelope = (samplesPerTone - i) / 200.0;

        final sample = (sin(2 * pi * freq * t) * 30000.0 * envelope).round();
        bytes.setInt16(offset, sample, Endian.little);
        offset += 2;
      }
    }

    return bytes.buffer.asUint8List();
  }

  static void _writeString(ByteData data, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}
