import 'package:flutter/foundation.dart';

enum SmsCategory {
  personal('Personal', 'Chats, family, and direct contacts'),
  transactions('Transactions', 'Bank alerts, receipts, and OTPs'),
  promotions('Promotions', 'Offers, deals, and commercial promos'),
  spam('Spam & Fraud', 'Phishing links, lottery scams, and blocked SMS');

  final String label;
  final String description;
  const SmsCategory(this.label, this.description);
}

@immutable
class SmartSmsMessage {
  final String id;
  final String sender;
  final String body;
  final DateTime timestamp;
  final SmsCategory category;
  final String? otpCode;
  final String? extractedUrl;
  final bool isPhishing;
  final bool isRead;

  const SmartSmsMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.timestamp,
    required this.category,
    this.otpCode,
    this.extractedUrl,
    this.isPhishing = false,
    this.isRead = true,
  });

  static String? extractOtp(String body) {
    final lower = body.toLowerCase();
    if (lower.contains('otp') ||
        lower.contains('code') ||
        lower.contains('verification') ||
        lower.contains('pin') ||
        lower.contains('password')) {
      final reg = RegExp(r'\b([0-9]{4,8})\b');
      final match = reg.firstMatch(body);
      return match?.group(1);
    }
    return null;
  }

  static String? extractUrl(String body) {
    final reg = RegExp(r'(https?:\/\/[^\s]+|www\.[^\s]+|[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}\/[^\s]*)');
    final match = reg.firstMatch(body);
    return match?.group(0);
  }

  SmartSmsMessage copyWith({
    String? id,
    String? sender,
    String? body,
    DateTime? timestamp,
    SmsCategory? category,
    String? otpCode,
    String? extractedUrl,
    bool? isPhishing,
    bool? isRead,
  }) {
    return SmartSmsMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      otpCode: otpCode ?? this.otpCode,
      extractedUrl: extractedUrl ?? this.extractedUrl,
      isPhishing: isPhishing ?? this.isPhishing,
      isRead: isRead ?? this.isRead,
    );
  }
}
