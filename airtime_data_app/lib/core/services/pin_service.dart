// Transaction PIN Service
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'transaction_pin';

  static Future<bool> hasPin() async {
    final pin = await _storage.read(key: _key);
    return pin != null && pin.isNotEmpty;
  }

  static Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _key);
    return stored == pin;
  }

  static Future<void> setPin(String pin) async {
    await _storage.write(key: _key, value: pin);
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _key);
  }
}
