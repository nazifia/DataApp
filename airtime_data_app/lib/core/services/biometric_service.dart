import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'biometric_enabled';
  static final _localAuth = LocalAuthentication();

  static Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _key);
    return v == 'true';
  }

  static Future<bool> isDeviceCapable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enable() async {
    try {
      final capable = await isDeviceCapable();
      if (!capable) return false;
      final auth = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to enable biometric login',
      );
      if (auth) {
        await _storage.write(key: _key, value: 'true');
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> disable() async {
    await _storage.write(key: _key, value: 'false');
  }
}
