import 'package:flutter_test/flutter_test.dart';
import 'package:callshield_app/domain/models/permission_models.dart';
import 'package:callshield_app/presentation/state/permissions_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionSnapshot & Capability Tests', () {
    test('readinessScore computes 100 when all capabilities granted', () {
      final snapshot = PermissionSnapshot(
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

      expect(snapshot.readinessScore, equals(100));
      expect(snapshot.isFullyProtected, isTrue);
      expect(snapshot.hasCoreTelephony, isTrue);
      expect(snapshot.hasSmsProtection, isTrue);
    });

    test('readinessScore computes accurately for partial permissions', () {
      final emptySnapshot = PermissionSnapshot();
      expect(emptySnapshot.readinessScore, equals(0));
      expect(emptySnapshot.isFullyProtected, isFalse);

      final telephonyOnly = PermissionSnapshot(
        callScreeningRole: true,
        readCallLog: true,
        readContacts: true,
      );
      // 30 + 15 + 15 = 60
      expect(telephonyOnly.readinessScore, equals(60));
      expect(telephonyOnly.hasCoreTelephony, isTrue);
      expect(telephonyOnly.hasSmsProtection, isFalse);
    });

    test('fromMap parses all 8 capabilities accurately', () {
      final map = {
        'callScreening': true,
        'readCallLog': false,
        'readContacts': true,
        'readSms': true,
        'receiveSms': true,
        'notificationAccess': true,
        'overlay': false,
        'batteryExempt': true,
        'postNotifications': false,
      };

      final snapshot = PermissionSnapshot.fromMap(map);
      expect(snapshot.callScreeningRole, isTrue);
      expect(snapshot.readCallLog, isFalse);
      expect(snapshot.readContacts, isTrue);
      expect(snapshot.notificationAccess, isTrue);
      expect(snapshot.batteryExempt, isTrue);
      expect(snapshot.overlay, isFalse);
    });

    test('contracts list contains all 9 system capability definitions', () {
      expect(PermissionSnapshot.contracts.length, equals(9));
      final ids = PermissionSnapshot.contracts.map((c) => c.id).toSet();
      expect(ids.contains(PermissionCapabilityId.notificationAccess), isTrue);
      expect(ids.contains(PermissionCapabilityId.callScreeningRole), isTrue);
      expect(ids.contains(PermissionCapabilityId.batteryExempt), isTrue);
      expect(ids.contains(PermissionCapabilityId.overlay), isTrue);
    });
  });

  group('PermissionsProvider Tests', () {
    test('initializes and computes capability states', () async {
      final provider = PermissionsProvider();
      await provider.refresh();

      expect(provider.snapshot, isNotNull);
      expect(provider.allCapabilityStates.length, equals(9));
    });
  });
}
