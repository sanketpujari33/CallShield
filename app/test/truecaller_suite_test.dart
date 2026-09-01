import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callshield_app/domain/models/smart_sms_models.dart';
import 'package:callshield_app/domain/models/call_recording_models.dart';
import 'package:callshield_app/domain/models/assistant_screener_models.dart';
import 'package:callshield_app/presentation/screens/assistant/ai_assistant_screen.dart';
import 'package:callshield_app/presentation/screens/sms/smart_sms_inbox_screen.dart';
import 'package:callshield_app/presentation/screens/messenger_shield/app_messenger_shield_screen.dart';
import 'package:callshield_app/presentation/screens/recording/call_recording_hub_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Truecaller Flagship Suite Model & Helper Tests', () {
    test('SmartSmsMessage.extractOtp parses 4, 6, and 8 digit verification codes', () {
      expect(SmartSmsMessage.extractOtp('Your Chase login OTP is 849201. Do not share.'), equals('849201'));
      expect(SmartSmsMessage.extractOtp('Your Uber code is 3910.'), equals('3910'));
      expect(SmartSmsMessage.extractOtp('Your verification PIN is 91827364.'), equals('91827364'));
      expect(SmartSmsMessage.extractOtp('Hello from John, call me back!'), isNull);
    });

    test('SmartSmsMessage.extractUrl extracts phishing and promotional links', () {
      expect(
        SmartSmsMessage.extractUrl('Pay fee here: http://usps-parcel-redelivery-fee.ru/pay to claim.'),
        equals('http://usps-parcel-redelivery-fee.ru/pay'),
      );
      expect(
        SmartSmsMessage.extractUrl('50% off deals at https://dominos.app/deal'),
        equals('https://dominos.app/deal'),
      );
    });

    test('CallRecording model duration formatting and waveform properties', () {
      final rec = CallRecording(
        id: 'rec_test',
        callerName: 'Test Caller',
        phoneNumber: '+18005550199',
        timestamp: DateTime.now(),
        durationSeconds: 125,
        filePath: '/path/test.m4a',
        fileSizeFormatted: '1.2 MB',
        isIncoming: true,
        transcript: 'Transcript text sample',
      );
      expect(rec.durationFormatted, equals('02:05'));
      expect(rec.waveform.isNotEmpty, isTrue);
    });

    test('AssistantPersona and TranscriptMessage model integrity', () {
      expect(AssistantPersona.values.length, equals(4));
      final msg = TranscriptMessage(
        speaker: ScreenerSpeaker.assistant,
        text: 'Hello from AI',
        timestamp: DateTime(2026, 1, 1),
      );
      expect(msg.speaker, equals(ScreenerSpeaker.assistant));
      expect(msg.text, equals('Hello from AI'));
    });
  });

  group('Truecaller Flagship Screens Widget Tests', () {
    testWidgets('AiAssistantScreen renders and displays AI Call Screening title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AiAssistantScreen()),
      );
      expect(find.text('CallShield AI Assistant'), findsOneWidget);
      expect(find.text('Call Screening by AI'), findsOneWidget);
      expect(find.text('Test Simulation'), findsOneWidget);
    });

    testWidgets('SmartSmsInboxScreen renders with 4 category tabs and message cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SmartSmsInboxScreen()),
      );
      expect(find.text('Smart SMS & Fraud Shield'), findsOneWidget);
      expect(find.textContaining('Personal'), findsOneWidget);
      expect(find.textContaining('Transactions'), findsOneWidget);
      expect(find.textContaining('Promotions'), findsOneWidget);
      expect(find.textContaining('Spam'), findsOneWidget);
    });

    testWidgets('AppMessengerShieldScreen renders with WhatsApp & Telegram toggles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppMessengerShieldScreen()),
      );
      expect(find.text('WhatsApp & Messenger Shield'), findsOneWidget);
      expect(find.text('WhatsApp Call Shield'), findsOneWidget);
      expect(find.text('Telegram Call & Channel Shield'), findsOneWidget);
    });

    testWidgets('CallRecordingHubScreen renders with recording preferences and audio list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CallRecordingHubScreen()),
      );
      expect(find.text('Call Recording Hub'), findsOneWidget);
      expect(find.text('Auto-Record All Calls'), findsOneWidget);
      expect(find.textContaining('RECORDED CALLS'), findsOneWidget);
    });
  });
}
