import 'package:flutter/foundation.dart';

enum CallerType {
  verifiedDelivery,
  verifiedBusiness,
  personalContact,
  telemarketing,
  spamRobocall,
  scamPhishing,
  unknown,
}

enum VerificationLevel {
  verified,
  unverified,
  suspicious,
  malicious,
}

enum StirShakenAttestation {
  fullA,       // Level A: Verified identity & number authorization
  partialB,    // Level B: Verified customer, unknown origin
  gatewayC,    // Level C: International gateway entry
  spoofed,     // Unauthenticated / Spoofed
  unavailable,
}

@immutable
class CallerIdentity {
  final String rawNumber;
  final String formattedNumber;
  final String name;
  final String categoryName;
  final CallerType type;
  final VerificationLevel verificationLevel;
  final StirShakenAttestation attestation;
  final String location;
  final String carrier;
  final int spamScore; // 0 (clean) to 100 (extreme threat)
  final int reportCount;
  final String highlightMessage;
  final String? avatarUrl;
  final List<String> tags;
  final bool isBlocked;

  const CallerIdentity({
    required this.rawNumber,
    required this.formattedNumber,
    required this.name,
    required this.categoryName,
    required this.type,
    required this.verificationLevel,
    this.attestation = StirShakenAttestation.fullA,
    required this.location,
    required this.carrier,
    this.spamScore = 0,
    this.reportCount = 0,
    required this.highlightMessage,
    this.avatarUrl,
    this.tags = const [],
    this.isBlocked = false,
  });

  bool get isSpam => spamScore >= 50 || type == CallerType.spamRobocall || type == CallerType.scamPhishing;
  bool get isVerified => verificationLevel == VerificationLevel.verified;
  bool get isDelivery => type == CallerType.verifiedDelivery;

  CallerIdentity copyWith({
    String? rawNumber,
    String? formattedNumber,
    String? name,
    String? categoryName,
    CallerType? type,
    VerificationLevel? verificationLevel,
    StirShakenAttestation? attestation,
    String? location,
    String? carrier,
    int? spamScore,
    int? reportCount,
    String? highlightMessage,
    String? avatarUrl,
    List<String>? tags,
    bool? isBlocked,
  }) {
    return CallerIdentity(
      rawNumber: rawNumber ?? this.rawNumber,
      formattedNumber: formattedNumber ?? this.formattedNumber,
      name: name ?? this.name,
      categoryName: categoryName ?? this.categoryName,
      type: type ?? this.type,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      attestation: attestation ?? this.attestation,
      location: location ?? this.location,
      carrier: carrier ?? this.carrier,
      spamScore: spamScore ?? this.spamScore,
      reportCount: reportCount ?? this.reportCount,
      highlightMessage: highlightMessage ?? this.highlightMessage,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tags: tags ?? this.tags,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
