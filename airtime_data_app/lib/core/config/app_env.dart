// App Environment Configuration
import 'package:flutter/foundation.dart' show kIsWeb;

enum AppEnvironment { dev, prod }

class AppConfig {
  final AppEnvironment environment;
  final String baseUrl;
  final String tenantSlug;
  final bool enableLogging;
  final bool useMockAuth;
  final String testOtp;

  const AppConfig({
    required this.environment,
    required this.baseUrl,
    required this.tenantSlug,
    required this.enableLogging,
    required this.useMockAuth,
    required this.testOtp,
  });

  bool get isDev => environment == AppEnvironment.dev;

  // kIsWeb: browser uses localhost; Android emulator uses 10.0.2.2
  static AppConfig get dev => AppConfig(
    environment: AppEnvironment.dev,
    baseUrl: kIsWeb
        ? 'http://localhost:8000/api/v1'
        : 'http://10.0.2.2:8000/api/v1',
    tenantSlug: 'default',
    enableLogging: true,
    useMockAuth: false,
    testOtp: '123456',
  );

  static const AppConfig prod = AppConfig(
    environment: AppEnvironment.prod,
    baseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://topupnaija.pythonanywhere.com/api/v1',
    ),
    tenantSlug: 'default',
    enableLogging: false,
    useMockAuth: false,
    testOtp: '',
  );

  // Single source of truth for the active environment.
  // Build with --dart-define=PROD=true to select prod (default: dev).
  // Override the API host with --dart-define=API_BASE_URL=https://...
  static const bool _isProd = bool.fromEnvironment('PROD');

  static AppConfig get active => _isProd ? prod : dev;
}
