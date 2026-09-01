import 'package:flutter/foundation.dart';

@immutable
class CallRecording {
  final String id;
  final String callerName;
  final String phoneNumber;
  final DateTime timestamp;
  final int durationSeconds;
  final String filePath;
  final String fileSizeFormatted;
  final bool isIncoming;
  final String transcript;
  final List<double> waveform;

  const CallRecording({
    required this.id,
    required this.callerName,
    required this.phoneNumber,
    required this.timestamp,
    required this.durationSeconds,
    required this.filePath,
    required this.fileSizeFormatted,
    required this.isIncoming,
    required this.transcript,
    this.waveform = const [0.2, 0.4, 0.7, 0.9, 0.6, 0.3, 0.5, 0.8, 1.0, 0.7, 0.4, 0.6, 0.8, 0.5, 0.2],
  });

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
