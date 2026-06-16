import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Owns biometric enrollment and the OS fingerprint/face prompt.
///
/// Security model: biometrics gate access to the user's *refresh token*, which
/// is persisted in the platform secure store (Keystore/Keychain). A biometric
/// login verifies identity locally and then exchanges that refresh token for a
/// fresh access token — it never bypasses the backend session.
class BiometricService {
  static const _storage = FlutterSecureStorage();
  static const _enabledKey = 'biometric_enabled';
  static const _phoneKey = 'biometric_phone';
  static const _tokenKey = 'biometric_refresh_token';
  static final _localAuth = LocalAuthentication();

  static Future<bool> isBiometricEnabled() async {
    return (await _storage.read(key: _enabledKey)) == 'true';
  }

  /// True when the device has biometric hardware enrolled or a secure lock.
  static Future<bool> isDeviceCapable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompt the OS biometric sheet. Returns true only on a successful match.
  /// Falls back to device PIN/pattern (biometricOnly: false) so an enrolled
  /// user is never locked out if a sensor read fails.
  static Future<bool> authenticate(
      {String reason = 'Authenticate to continue'}) async {
    try {
      if (!await isDeviceCapable()) return false;
      return await _localAuth.authenticate(
        localizedReason: reason,
        // Allow device PIN/pattern fallback so an enrolled user is never
        // locked out if a sensor read fails.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  /// Enroll biometric login. Verifies identity, then copies the live refresh
  /// token into a biometric-gated slot. Must be called while logged in
  /// (a refresh token must already be in secure storage). Returns false if the
  /// prompt is declined or no session is present.
  static Future<bool> enable({String? phone}) async {
    final ok = await authenticate(
        reason: 'Verify your identity to enable biometric login');
    if (!ok) return false;
    final refresh = await _storage.read(key: 'refresh_token');
    if (refresh == null || refresh.isEmpty) return false;
    await _storage.write(key: _enabledKey, value: 'true');
    await _storage.write(key: _tokenKey, value: refresh);
    if (phone != null && phone.isNotEmpty) {
      await _storage.write(key: _phoneKey, value: phone);
    }
    return true;
  }

  /// Disable and forget the stored credential.
  static Future<void> disable() async {
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _tokenKey);
  }

  static Future<String?> savedRefreshToken() => _storage.read(key: _tokenKey);

  static Future<String?> savedPhone() => _storage.read(key: _phoneKey);

  /// Keep the biometric-stored token in sync after a normal login (refresh
  /// tokens rotate / change on password reset). No-op when not enrolled.
  static Future<void> refreshCredential(String refreshToken) async {
    if (refreshToken.isEmpty) return;
    if (await isBiometricEnabled()) {
      await _storage.write(key: _tokenKey, value: refreshToken);
    }
  }
}
