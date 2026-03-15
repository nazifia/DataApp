// Theme Service — persists and loads ThemeMode from secure storage
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';

  /// Load the persisted ThemeMode. Returns [ThemeMode.system] if none saved.
  static Future<ThemeMode> loadThemeMode() async {
    final value = await _storage.read(key: _key);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Persist the given [ThemeMode].
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await _storage.write(key: _key, value: value);
  }
}
