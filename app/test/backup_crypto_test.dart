import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:callshield_app/core/utils/crypto_utils.dart';

void main() {
  group('CryptoUtils Portable Backup', () {
    test('encrypts and decrypts payload with PBKDF2-HMAC-SHA256 and AES-256-GCM', () {
      const originalPayload = '{"app":"CallShield","version":"1.7.38","blocklist":[{"number":"+12125551234"}]}';
      const passphrase = 'MySuperSecretSecurePassphrase123!';

      final encryptedJson = CryptoUtils.encryptBackup(originalPayload, passphrase);
      expect(encryptedJson, isNotEmpty);
      expect(encryptedJson, contains('PBKDF2-HMAC-SHA256'));
      expect(encryptedJson, contains('AES-256-GCM'));

      final decrypted = CryptoUtils.decryptBackup(encryptedJson, passphrase);
      expect(decrypted, equals(originalPayload));

      final Map<String, dynamic> data = jsonDecode(decrypted);
      expect(data['app'], equals('CallShield'));
      expect(data['blocklist'], isNotEmpty);
    });

    test('fails to decrypt with incorrect passphrase', () {
      const originalPayload = '{"app":"CallShield"}';
      final encryptedJson = CryptoUtils.encryptBackup(originalPayload, 'correctPassword');

      expect(
        () => CryptoUtils.decryptBackup(encryptedJson, 'wrongPassword'),
        throwsA(anything),
      );
    });
  });
}
