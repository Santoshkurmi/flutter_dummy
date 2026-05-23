import 'package:flutter/services.dart';

class BiometricSignatureService {
  static const MethodChannel _channel = MethodChannel('com.brightbank.app/biometrics');

  /// Checks if strong biometric authentication capability exists on the device.
  static Future<bool> isAvailable() async {
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('isAvailable');
      return res?['isAvailable'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Generates a new hardware-backed RSA keypair in KeyStore, returning public key in PEM.
  static Future<String> createKeyPair(String mobile) async {
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('createKeyPair', {
        'alias': 'mb_auth_key_$mobile',
      });
      final pubKey = res?['publicKey'] as String?;
      if (pubKey == null) {
        throw Exception('Public key not returned from Keystore.');
      }
      return pubKey;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Hardware key pair creation failed.');
    }
  }

  /// Signs challenge string using secure hardware private key, prompting user fingerprint/face.
  static Future<String> signChallenge(String mobile, String challenge) async {
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('sign', {
        'alias': 'mb_auth_key_$mobile',
        'data': challenge,
        'title': 'Biometric Login',
        'subtitle': 'Authenticate to sign your secure login request',
      });
      final sig = res?['signature'] as String?;
      if (sig == null) {
        throw Exception('Signature not returned from Keystore.');
      }
      return sig;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Biometric challenge signing failed.');
    }
  }

  /// Displays simple biometric verification prompt for identity checks (no crypto).
  static Future<bool> verifyIdentity({String? title, String? subtitle}) async {
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('authenticate', {
        'title': title ?? 'Verify Identity',
        'subtitle': subtitle ?? 'Confirm your fingerprint to continue',
      });
      return res?['verified'] == true;
    } catch (_) {
      return false;
    }
  }
}
