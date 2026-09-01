import 'package:flutter/services.dart';

class CallShieldPlatform {
  static const MethodChannel _channel = MethodChannel('com.sysadmindoc.callshield/platform');

  static final CallShieldPlatform instance = CallShieldPlatform._();
  CallShieldPlatform._();

  Future<bool> isCallScreeningSupported() async {
    try {
      final res = await _channel.invokeMethod<bool>('isCallScreeningSupported');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isCallScreeningEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('isCallScreeningEnabled');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestCallScreeningRole() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestCallScreeningRole');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reloadCallDirectory() async {
    try {
      final res = await _channel.invokeMethod<bool>('reloadCallDirectory');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> getContactsPermissionStatus() async {
    try {
      final res = await _channel.invokeMethod<bool>('getContactsPermissionStatus');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestContactsPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestContactsPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> getSmsPermissionStatus() async {
    try {
      final res = await _channel.invokeMethod<bool>('getSmsPermissionStatus');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestSmsPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestSmsPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> getCallLogPermissionStatus() async {
    try {
      final res = await _channel.invokeMethod<bool>('getCallLogPermissionStatus');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestCallLogPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestCallLogPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCallLog({int limit = 200}) async {
    try {
      final res = await _channel.invokeListMethod<Map<dynamic, dynamic>>('getCallLog', {'limit': limit});
      if (res != null) {
        return res.map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getSmsInbox({int limit = 200}) async {
    try {
      final res = await _channel.invokeListMethod<Map<dynamic, dynamic>>('getSmsInbox', {'limit': limit});
      if (res != null) {
        return res.map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getDeviceContacts({int limit = 500}) async {
    try {
      final res = await _channel.invokeListMethod<Map<dynamic, dynamic>>('getDeviceContacts', {'limit': limit});
      if (res != null) {
        return res.map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> getNotificationAccessStatus() async {
    try {
      final res = await _channel.invokeMethod<bool>('getNotificationAccessStatus');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestNotificationAccess() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestNotificationAccess');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> getOverlayPermissionStatus() async {
    try {
      final res = await _channel.invokeMethod<bool>('getOverlayPermissionStatus');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestOverlayPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestOverlayPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> getBatteryOptimizationStatus() async {
    try {
      final res = await _channel.invokeMethod<bool>('getBatteryOptimizationStatus');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> getPostNotificationsPermissionStatus() async {
    try {
      final res = await _channel.invokeMethod<bool>('getPostNotificationsPermissionStatus');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPostNotificationsPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestPostNotificationsPermission');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, bool>> getAllPermissionsSnapshot() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getAllPermissionsSnapshot');
      if (res != null) {
        return res.map((k, v) => MapEntry(k, v == true));
      }
    } catch (_) {}
    return {};
  }

  Future<bool> openAppSettings() async {
    try {
      final res = await _channel.invokeMethod<bool>('openAppSettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openNotificationSettings() async {
    try {
      final res = await _channel.invokeMethod<bool>('openNotificationSettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
