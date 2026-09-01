import 'package:flutter/foundation.dart';

enum AssistantPersona {
  friendly('Friendly Assistant', 'Casual, warm, and helpful tone'),
  professional('Professional Executive', 'Polite, clear, and business-focused'),
  direct('Security Filter', 'Direct, strict spam screening'),
  formal('Formal Receptionist', 'Formal, structured inquiry');

  final String label;
  final String description;
  const AssistantPersona(this.label, this.description);
}

enum ScreenerSpeaker {
  assistant,
  caller,
  system,
}

@immutable
class TranscriptMessage {
  final ScreenerSpeaker speaker;
  final String text;
  final DateTime timestamp;
  final bool isFinal;

  const TranscriptMessage({
    required this.speaker,
    required this.text,
    required this.timestamp,
    this.isFinal = true,
  });
}

enum CallScreenerAction {
  pickUp('Pick Up Call', 'Connect voice call now'),
  askMoreInfo('Ask More Info', 'Inquire who is calling and purpose'),
  tellBusy('Tell Them I am Busy', 'Inform caller to leave a message or call later'),
  reportAndBlock('Hang Up & Block', 'Terminate call and blacklist number');

  final String label;
  final String hint;
  const CallScreenerAction(this.label, this.hint);
}
