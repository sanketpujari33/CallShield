import 'package:flutter/foundation.dart';

enum PermissionCapabilityId {
  callScreeningRole,
  readCallLog,
  readContacts,
  readSms,
  receiveSms,
  notificationAccess,
  overlay,
  batteryExempt,
  postNotifications,
}

enum PermissionKind {
  androidRole,
  runtimePermission,
  specialAccess,
  systemSetting,
}

enum PermissionPriority {
  required,
  recommended,
  optional,
}

enum PermissionStatus {
  ready,
  advisory,
  degraded,
  unsupported,
}

class PermissionCapabilityContract {
  final PermissionCapabilityId id;
  final PermissionKind kind;
  final PermissionPriority priority;
  final String name;
  final String shortDescription;
  final String grantedDetail;
  final String degradedDetail;
  final String whyNeeded;
  final String recoveryHint;

  const PermissionCapabilityContract({
    required this.id,
    required this.kind,
    required this.priority,
    required this.name,
    required this.shortDescription,
    required this.grantedDetail,
    required this.degradedDetail,
    required this.whyNeeded,
    required this.recoveryHint,
  });
}

class PermissionCapabilityState {
  final PermissionCapabilityContract contract;
  final PermissionStatus status;
  final bool isGranted;

  const PermissionCapabilityState({
    required this.contract,
    required this.status,
    required this.isGranted,
  });

  bool get isReady => status == PermissionStatus.ready;
  bool get isDegraded => status == PermissionStatus.degraded;
}

@immutable
class PermissionSnapshot {
  final bool callScreeningRole;
  final bool readCallLog;
  final bool readContacts;
  final bool readSms;
  final bool receiveSms;
  final bool notificationAccess;
  final bool overlay;
  final bool batteryExempt;
  final bool postNotifications;
  final DateTime timestamp;

  PermissionSnapshot({
    this.callScreeningRole = false,
    this.readCallLog = false,
    this.readContacts = false,
    this.readSms = false,
    this.receiveSms = false,
    this.notificationAccess = false,
    this.overlay = false,
    this.batteryExempt = false,
    this.postNotifications = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool isCapabilityGranted(PermissionCapabilityId id) {
    switch (id) {
      case PermissionCapabilityId.callScreeningRole:
        return callScreeningRole;
      case PermissionCapabilityId.readCallLog:
        return readCallLog;
      case PermissionCapabilityId.readContacts:
        return readContacts;
      case PermissionCapabilityId.readSms:
        return readSms;
      case PermissionCapabilityId.receiveSms:
        return receiveSms;
      case PermissionCapabilityId.notificationAccess:
        return notificationAccess;
      case PermissionCapabilityId.overlay:
        return overlay;
      case PermissionCapabilityId.batteryExempt:
        return batteryExempt;
      case PermissionCapabilityId.postNotifications:
        return postNotifications;
    }
  }

  /// Calculates protection readiness score between 0 and 100
  int get readinessScore {
    int score = 0;
    // Core weights
    if (callScreeningRole) score += 30;
    if (readCallLog) score += 15;
    if (readContacts) score += 15;
    if (readSms && receiveSms) {
      score += 15;
    } else if (readSms || receiveSms) {
      score += 7;
    }
    if (notificationAccess) score += 10;
    if (overlay) score += 5;
    if (batteryExempt) score += 5;
    if (postNotifications) score += 5;
    return score.clamp(0, 100);
  }

  bool get isFullyProtected => readinessScore >= 95;
  bool get hasCoreTelephony => callScreeningRole && readCallLog && readContacts;
  bool get hasSmsProtection => readSms && receiveSms;

  factory PermissionSnapshot.fromMap(Map<String, dynamic> map) {
    return PermissionSnapshot(
      callScreeningRole: map['callScreening'] == true,
      readCallLog: map['readCallLog'] == true,
      readContacts: map['readContacts'] == true,
      readSms: map['readSms'] == true,
      receiveSms: map['receiveSms'] == true,
      notificationAccess: map['notificationAccess'] == true,
      overlay: map['overlay'] == true,
      batteryExempt: map['batteryExempt'] == true,
      postNotifications: map['postNotifications'] == true,
    );
  }

  static const List<PermissionCapabilityContract> contracts = [
    PermissionCapabilityContract(
      id: PermissionCapabilityId.callScreeningRole,
      kind: PermissionKind.androidRole,
      priority: PermissionPriority.required,
      name: 'Call Screening Service',
      shortDescription: 'Active real-time gatekeeper',
      grantedDetail: 'Active Default Screener',
      degradedDetail: 'Not set as Call Screening app',
      whyNeeded: 'Required by Android to inspect caller ID & silence fraud calls before phone rings.',
      recoveryHint: 'Tap to grant Call Screening role in system dialog.',
    ),
    PermissionCapabilityContract(
      id: PermissionCapabilityId.readCallLog,
      kind: PermissionKind.runtimePermission,
      priority: PermissionPriority.required,
      name: 'Call History Access',
      shortDescription: 'Call log analysis & scanning',
      grantedDetail: 'Call Log Access Enabled',
      degradedDetail: 'Call history inaccessible',
      whyNeeded: 'Allows retroactive scam detection and Wangiri ping callback protection.',
      recoveryHint: 'Allow Call Logs access.',
    ),
    PermissionCapabilityContract(
      id: PermissionCapabilityId.readContacts,
      kind: PermissionKind.runtimePermission,
      priority: PermissionPriority.required,
      name: 'Contacts Whitelist',
      shortDescription: 'Known contact pass-through',
      grantedDetail: 'Contacts Synced for Whitelist',
      degradedDetail: 'Contacts not readable',
      whyNeeded: 'Guarantees friends, family, and colleagues never get accidentally blocked.',
      recoveryHint: 'Allow Contacts access.',
    ),
    PermissionCapabilityContract(
      id: PermissionCapabilityId.readSms,
      kind: PermissionKind.runtimePermission,
      priority: PermissionPriority.required,
      name: 'SMS Scanner',
      shortDescription: 'Inbox phishing & URL link scanner',
      grantedDetail: 'SMS Inbox Scan Active',
      degradedDetail: 'SMS access disabled',
      whyNeeded: 'Scans SMS messages for fake banking URLs, OTP theft, and phishing scams.',
      recoveryHint: 'Allow SMS read permission.',
    ),
    PermissionCapabilityContract(
      id: PermissionCapabilityId.receiveSms,
      kind: PermissionKind.runtimePermission,
      priority: PermissionPriority.required,
      name: 'Incoming SMS Interception',
      shortDescription: 'Real-time text spam shield',
      grantedDetail: 'Live SMS Interception Active',
      degradedDetail: 'Incoming SMS unmonitored',
      whyNeeded: 'Intercepts smishing texts the moment they reach the device.',
      recoveryHint: 'Allow SMS receive permission.',
    ),
    PermissionCapabilityContract(
      id: PermissionCapabilityId.notificationAccess,
      kind: PermissionKind.specialAccess,
      priority: PermissionPriority.recommended,
      name: 'Notification Listener Access',
      shortDescription: 'RCS & Messaging app screening',
      grantedDetail: 'Notification Shield Active',
      degradedDetail: 'Notification access disabled',
      whyNeeded: 'Enables scanning and threat detection for messages arriving via RCS or messaging notifications.',
      recoveryHint: 'Enable CallShield in Device Notification Access settings.',
    ),
    PermissionCapabilityContract(
      id: PermissionCapabilityId.overlay,
      kind: PermissionKind.specialAccess,
      priority: PermissionPriority.recommended,
      name: 'Display Over Other Apps',
      shortDescription: 'Heads-up caller risk badge',
      grantedDetail: 'Live Overlay Badge Enabled',
      degradedDetail: 'Overlay permission missing',
      whyNeeded: 'Displays caller reputation banner and threat score while call is incoming.',
      recoveryHint: 'Enable "Draw over other apps" in device settings.',
    ),
    PermissionCapabilityContract(
      id: PermissionCapabilityId.batteryExempt,
      kind: PermissionKind.systemSetting,
      priority: PermissionPriority.recommended,
      name: 'Background Battery Exemption',
      shortDescription: 'Uninterrupted screening protection',
      grantedDetail: 'Battery Saver Optimization Exempt',
      degradedDetail: 'OEM battery manager may kill service',
      whyNeeded: 'Prevents aggressive OEM task killers from terminating CallShield background workers.',
      recoveryHint: 'Exclude CallShield from battery optimization.',
    ),
    PermissionCapabilityContract(
      id: PermissionCapabilityId.postNotifications,
      kind: PermissionKind.runtimePermission,
      priority: PermissionPriority.recommended,
      name: 'Security Alerts & Notifications',
      shortDescription: 'Blocked threat notices',
      grantedDetail: 'Notification Alerts Enabled',
      degradedDetail: 'Security alerts silenced',
      whyNeeded: 'Alerts you whenever a high-risk scam or dangerous smishing attempt is blocked.',
      recoveryHint: 'Enable app notifications in system settings.',
    ),
  ];
}
