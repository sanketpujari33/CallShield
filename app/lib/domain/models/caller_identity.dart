enum VerificationStatus {
  notVerified,
  passed,
  failed,
}

enum AttestationLevel {
  a, // Full attestation
  b, // Partial attestation
  c, // Gateway attestation
  none,
}

class CallerIdentity {
  final String rawNumber;
  final String normalizedNumber;
  final String displayName;
  final String carrier;
  final String location;
  final VerificationStatus verificationStatus;
  final AttestationLevel attestationLevel;
  final bool isContact;

  const CallerIdentity({
    required this.rawNumber,
    required this.normalizedNumber,
    this.displayName = '',
    this.carrier = '',
    this.location = '',
    this.verificationStatus = VerificationStatus.notVerified,
    this.attestationLevel = AttestationLevel.none,
    this.isContact = false,
  });
}
