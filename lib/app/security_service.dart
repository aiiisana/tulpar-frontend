import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';

class SecurityService {
  static const _pinHashKey = 'pin_hash';

  final _storage = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<bool> hasPin() async {
    final h = await _storage.read(key: _pinHashKey);
    return h != null && h.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinHashKey, value: _hash(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final saved = await _storage.read(key: _pinHashKey);
    if (saved == null || saved.isEmpty) return false;
    return _hash(pin) == saved;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
  }

  Future<bool> canBiometric() async {
    try {
      final can = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return can && supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Подтвердите вход',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
