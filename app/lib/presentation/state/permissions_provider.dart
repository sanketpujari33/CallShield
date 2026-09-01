import 'package:flutter/material.dart';
import '../../core/platform/callshield_platform.dart';
import '../../domain/models/permission_models.dart';

class PermissionsProvider extends ChangeNotifier {
  final CallShieldPlatform _platform;

  PermissionSnapshot _snapshot = PermissionSnapshot();
  bool _isLoading = false;

  PermissionsProvider({CallShieldPlatform? platform})
      : _platform = platform ?? CallShieldPlatform.instance {
    refresh();
  }

  PermissionSnapshot get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  int get readinessScore => _snapshot.readinessScore;
  bool get isFullyProtected => _snapshot.isFullyProtected;

  List<PermissionCapabilityContract> get missingRequired => PermissionSnapshot.contracts
      .where((c) => c.priority == PermissionPriority.required && !_snapshot.isCapabilityGranted(c.id))
      .toList();

  List<PermissionCapabilityContract> get missingRecommended => PermissionSnapshot.contracts
      .where((c) => c.priority == PermissionPriority.recommended && !_snapshot.isCapabilityGranted(c.id))
      .toList();

  List<PermissionCapabilityState> get allCapabilityStates {
    return PermissionSnapshot.contracts.map((contract) {
      final granted = _snapshot.isCapabilityGranted(contract.id);
      return PermissionCapabilityState(
        contract: contract,
        status: granted ? PermissionStatus.ready : PermissionStatus.degraded,
        isGranted: granted,
      );
    }).toList();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final map = await _platform.getAllPermissionsSnapshot();
      if (map.isNotEmpty) {
        _snapshot = PermissionSnapshot.fromMap(map);
      } else {
        // Fallback individual queries
        final screening = await _platform.isCallScreeningEnabled();
        final contacts = await _platform.getContactsPermissionStatus();
        final callLog = await _platform.getCallLogPermissionStatus();
        final sms = await _platform.getSmsPermissionStatus();
        final notifAccess = await _platform.getNotificationAccessStatus();
        final overlay = await _platform.getOverlayPermissionStatus();
        final battery = await _platform.getBatteryOptimizationStatus();
        final postNotif = await _platform.getPostNotificationsPermissionStatus();

        _snapshot = PermissionSnapshot(
          callScreeningRole: screening,
          readCallLog: callLog,
          readContacts: contacts,
          readSms: sms,
          receiveSms: sms,
          notificationAccess: notifAccess,
          overlay: overlay,
          batteryExempt: battery,
          postNotifications: postNotif,
        );
      }
    } catch (_) {
      // In simulation/desktop mode, provide safe defaults
      _snapshot = PermissionSnapshot(
        callScreeningRole: true,
        readCallLog: true,
        readContacts: true,
        readSms: true,
        receiveSms: true,
        notificationAccess: true,
        overlay: true,
        batteryExempt: true,
        postNotifications: true,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestCapability(PermissionCapabilityId id) async {
    bool result = false;
    switch (id) {
      case PermissionCapabilityId.callScreeningRole:
        result = await _platform.requestCallScreeningRole();
        break;
      case PermissionCapabilityId.readCallLog:
        result = await _platform.requestCallLogPermission();
        break;
      case PermissionCapabilityId.readContacts:
        result = await _platform.requestContactsPermission();
        break;
      case PermissionCapabilityId.readSms:
      case PermissionCapabilityId.receiveSms:
        result = await _platform.requestSmsPermission();
        break;
      case PermissionCapabilityId.notificationAccess:
        result = await _platform.requestNotificationAccess();
        break;
      case PermissionCapabilityId.overlay:
        result = await _platform.requestOverlayPermission();
        break;
      case PermissionCapabilityId.batteryExempt:
        result = await _platform.requestIgnoreBatteryOptimizations();
        break;
      case PermissionCapabilityId.postNotifications:
        result = await _platform.requestPostNotificationsPermission();
        break;
    }
    await refresh();
    return result;
  }

  Future<void> requestAllMissingRequired() async {
    for (final contract in missingRequired) {
      await requestCapability(contract.id);
    }
    await refresh();
  }

  Future<void> openAppSettings() async {
    await _platform.openAppSettings();
  }

  Future<void> openNotificationSettings() async {
    await _platform.openNotificationSettings();
  }

  Future<void> openNotificationListenerSettings() async {
    await _platform.requestNotificationAccess();
  }
}
