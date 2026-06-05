import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  factory EncryptionService() => _instance;
  EncryptionService._();

  Uint8List deriveKey(String pairingToken, String deviceId) {
    final input = utf8.encode('$pairingToken:$deviceId');
    final digest = SHA256Digest();
    final result = Uint8List(32);
    digest.update(Uint8List.fromList(input), 0, input.length);
    digest.doFinal(result, 0);
    return result;
  }

  String encrypt(String plaintext, Uint8List key) {
    final iv = _generateIv();
    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128,
      iv,
      Uint8List(0),
    );
    cipher.init(true, params);
    final input = utf8.encode(plaintext);
    final output = Uint8List(cipher.getOutputSize(input.length));
    final len = cipher.processBytes(
      Uint8List.fromList(input),
      0,
      input.length,
      output,
      0,
    );
    cipher.doFinal(output, len);

    final combined = Uint8List(iv.length + output.length);
    combined.setRange(0, iv.length, iv);
    combined.setRange(iv.length, combined.length, output);
    return base64Encode(combined);
  }

  String decrypt(String ciphertext, Uint8List key) {
    final combined = base64Decode(ciphertext);
    final iv = combined.sublist(0, 12);
    final encrypted = combined.sublist(12);

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128,
      iv,
      Uint8List(0),
    );
    cipher.init(false, params);
    final output = Uint8List(cipher.getOutputSize(encrypted.length));
    final len = cipher.processBytes(encrypted, 0, encrypted.length, output, 0);
    cipher.doFinal(output, len);
    return utf8.decode(output.sublist(0, len));
  }

  Uint8List _generateIv() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(12, (_) => random.nextInt(256)),
    );
  }

  static String generatePairingToken() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(Uint8List.fromList(bytes));
  }

  static String generatePin() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }
}
