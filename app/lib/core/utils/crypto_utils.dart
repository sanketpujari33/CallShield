import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

class CryptoUtils {
  static const int pbkdf2Iterations = 100000;
  static const int keyLengthBytes = 32; // 256 bits

  static Uint8List deriveKey(String passphrase, Uint8List salt) {
    final pbkdf2 = pc.KeyDerivator('SHA-256/HMAC/PBKDF2');
    final params = pc.Pbkdf2Parameters(salt, pbkdf2Iterations, keyLengthBytes);
    pbkdf2.init(params);
    return pbkdf2.process(Uint8List.fromList(utf8.encode(passphrase)));
  }

  static Uint8List generateRandomBytes(int length) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return bytes;
  }

  static String encryptBackup(String plaintext, String passphrase) {
    final salt = generateRandomBytes(16);
    final ivBytes = generateRandomBytes(12);
    final keyBytes = deriveKey(passphrase, salt);

    final key = enc.Key(keyBytes);
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    final envelope = {
      'version': 5,
      'kdf': 'PBKDF2-HMAC-SHA256',
      'cipher': 'AES-256-GCM',
      'iterations': pbkdf2Iterations,
      'salt': base64Encode(salt),
      'iv': base64Encode(ivBytes),
      'data': encrypted.base64,
    };

    return jsonEncode(envelope);
  }

  static String decryptBackup(String encryptedEnvelopeJson, String passphrase) {
    final Map<String, dynamic> envelope = jsonDecode(encryptedEnvelopeJson);
    final salt = base64Decode(envelope['salt'] as String);
    final ivBytes = base64Decode(envelope['iv'] as String);
    final cipherText = envelope['data'] as String;

    final keyBytes = deriveKey(passphrase, salt);
    final key = enc.Key(keyBytes);
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

    final decrypted = encrypter.decrypt64(cipherText, iv: iv);
    return decrypted;
  }

  static String sha256Hex(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
