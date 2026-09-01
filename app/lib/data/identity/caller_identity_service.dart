import '../../core/utils/phone_normalizer.dart';
import '../../domain/models/caller_identity_models.dart';
import '../ml/spam_ml_scorer.dart';

class CallerIdentityService {
  static final CallerIdentityService instance = CallerIdentityService._();
  CallerIdentityService._();

  static const List<CallerIdentity> presets = [
    CallerIdentity(
      rawNumber: '+918172033604',
      formattedNumber: '+91-81720 33604',
      name: 'Food Delivery',
      categoryName: 'Verified Courier • Swiggy / Zomato',
      type: CallerType.verifiedDelivery,
      verificationLevel: VerificationLevel.verified,
      attestation: StirShakenAttestation.fullA,
      location: 'New Delhi, India',
      carrier: 'Airtel Telecommunications',
      spamScore: 0,
      reportCount: 0,
      highlightMessage: 'Your biryani order is at your office reception.',
      tags: ['Delivery', 'Food & Dining', 'Priority'],
    ),
    CallerIdentity(
      rawNumber: '+18005550199',
      formattedNumber: '+1 (800) 555-0199',
      name: 'IRS Tax Law Enforcement',
      categoryName: '🚨 Impersonation Scam Alert',
      type: CallerType.scamPhishing,
      verificationLevel: VerificationLevel.malicious,
      attestation: StirShakenAttestation.spoofed,
      location: 'Washington, DC (Toll-Free)',
      carrier: 'VoIP Origin Gateway',
      spamScore: 98,
      reportCount: 4210,
      highlightMessage: 'Reported by 4,210 users: Threatening fake arrest warrant and demand for crypto / gift cards.',
      tags: ['IRS Scam', 'Impersonation', 'Robocall', 'Aggressive'],
    ),
    CallerIdentity(
      rawNumber: '+18884440123',
      formattedNumber: '+1 (888) 444-0123',
      name: 'Auto Warranty Services',
      categoryName: '📢 Telemarketing / Robocall',
      type: CallerType.telemarketing,
      verificationLevel: VerificationLevel.suspicious,
      attestation: StirShakenAttestation.gatewayC,
      location: 'Toll-Free, North America',
      carrier: 'Bandwidth.com CLEC',
      spamScore: 78,
      reportCount: 1530,
      highlightMessage: 'Automated robocall pitching expired vehicle protection plans.',
      tags: ['Auto Warranty', 'Telemarketing', 'Robocall', 'Recorded'],
    ),
    CallerIdentity(
      rawNumber: '+12125550144',
      formattedNumber: '+1 (212) 555-0144',
      name: 'Amazon Prime Logistics',
      categoryName: 'Package Dispatch & Delivery',
      type: CallerType.verifiedDelivery,
      verificationLevel: VerificationLevel.verified,
      attestation: StirShakenAttestation.fullA,
      location: 'Manhattan, New York, US',
      carrier: 'Verizon Business',
      spamScore: 2,
      reportCount: 0,
      highlightMessage: 'Driver is arriving in 5 minutes with your scheduled electronics delivery.',
      tags: ['Amazon', 'Package Delivery', 'Verified Business'],
    ),
    CallerIdentity(
      rawNumber: '+14155552671',
      formattedNumber: '+1 (415) 555-2671',
      name: 'Sarah Jenkins',
      categoryName: 'Personal Contact • Address Book',
      type: CallerType.personalContact,
      verificationLevel: VerificationLevel.verified,
      attestation: StirShakenAttestation.fullA,
      location: 'San Francisco, CA, US',
      carrier: 'AT&T Wireless',
      spamScore: 0,
      reportCount: 0,
      highlightMessage: 'Incoming call from your saved contact list.',
      tags: ['Contact', 'Trusted', 'Family & Friends'],
    ),
  ];

  /// Resolves any phone number into a comprehensive CallerIdentity profile
  CallerIdentity resolve(String inputNumber, {String? contactName}) {
    final cleaned = PhoneNormalizer.normalize(inputNumber) ?? inputNumber;
    final formatted = PhoneNormalizer.formatDisplay(cleaned);

    // Check presets first for full-fidelity demonstration
    for (final preset in presets) {
      if (preset.rawNumber == cleaned || preset.formattedNumber == inputNumber) {
        return preset;
      }
    }

    // Geolocation from area code or country prefix
    String location = 'Regional Line';
    if (cleaned.startsWith('+1')) {
      location = _resolveUSAreaCode(cleaned);
    } else if (cleaned.startsWith('+91')) {
      location = 'India (National Gateway)';
    } else if (cleaned.startsWith('+44')) {
      location = 'United Kingdom (Telecom)';
    }

    // Check known contacts
    if (contactName != null && contactName.isNotEmpty) {
      return CallerIdentity(
        rawNumber: cleaned,
        formattedNumber: formatted,
        name: contactName,
        categoryName: 'Personal Contact',
        type: CallerType.personalContact,
        verificationLevel: VerificationLevel.verified,
        attestation: StirShakenAttestation.fullA,
        location: location,
        carrier: 'Mobile Carrier',
        spamScore: 0,
        reportCount: 0,
        highlightMessage: 'Verified contact in your address book.',
        tags: ['Contact', 'Trusted'],
      );
    }

    // GBDT ML Threat Assessment
    final scoreDouble = SpamMLScorer.instance.score(cleaned);
    final spamScore = (scoreDouble * 100).toInt().clamp(0, 100);

    // Determine category based on threat score and number characteristics
    if (spamScore >= 80 || cleaned.startsWith('+1809') || cleaned.startsWith('+1829')) {
      return CallerIdentity(
        rawNumber: cleaned,
        formattedNumber: formatted,
        name: 'High-Risk Suspected Scam',
        categoryName: '🚨 Malicious Call Alert',
        type: CallerType.scamPhishing,
        verificationLevel: VerificationLevel.malicious,
        attestation: StirShakenAttestation.spoofed,
        location: location,
        carrier: 'International / VoIP Route',
        spamScore: spamScore,
        reportCount: 840,
        highlightMessage: 'GBDT ML Threat Engine identified high-risk spoofing and financial fraud patterns.',
        tags: ['Phishing', 'Scam', 'High Risk', 'ML Flagged'],
      );
    } else if (spamScore >= 50 || cleaned.startsWith('+1800') || cleaned.startsWith('+1888')) {
      return CallerIdentity(
        rawNumber: cleaned,
        formattedNumber: formatted,
        name: 'Telemarketing / Promo Line',
        categoryName: '📢 Unsolicited Commercial Call',
        type: CallerType.telemarketing,
        verificationLevel: VerificationLevel.suspicious,
        attestation: StirShakenAttestation.partialB,
        location: location,
        carrier: 'Telecom Toll-Free Route',
        spamScore: spamScore,
        reportCount: 320,
        highlightMessage: 'Reported as unsolicited promotional sales call.',
        tags: ['Telemarketing', 'Sales Promo', 'Robocall'],
      );
    } else {
      return CallerIdentity(
        rawNumber: cleaned,
        formattedNumber: formatted,
        name: 'Standard Regional Caller',
        categoryName: 'Unverified Number',
        type: CallerType.unknown,
        verificationLevel: VerificationLevel.unverified,
        attestation: StirShakenAttestation.gatewayC,
        location: location,
        carrier: 'Domestic Landline/Mobile',
        spamScore: spamScore,
        reportCount: 0,
        highlightMessage: 'No community spam reports on record.',
        tags: ['Unclassified', 'Standard Line'],
      );
    }
  }

  String _resolveUSAreaCode(String e164) {
    if (e164.length < 5) return 'United States';
    final npa = e164.substring(2, 5);
    switch (npa) {
      case '212':
      case '646':
      case '332':
      case '718':
      case '917':
      case '347':
        return 'New York, NY, US';
      case '415':
      case '628':
        return 'San Francisco, CA, US';
      case '213':
      case '310':
      case '323':
      case '424':
        return 'Los Angeles, CA, US';
      case '312':
      case '773':
        return 'Chicago, IL, US';
      case '202':
        return 'Washington, DC, US';
      case '800':
      case '888':
      case '877':
      case '866':
      case '855':
      case '844':
      case '833':
        return 'Toll-Free, North America';
      default:
        return 'US Regional Line ($npa)';
    }
  }
}
