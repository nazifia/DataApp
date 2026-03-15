// App Environment Configuration
enum AppEnvironment { dev, prod }

class AppConfig {
  final AppEnvironment environment;
  final String baseUrl;
  final bool enableLogging;
  final bool useMockAuth;
  final String testOtp;

  const AppConfig({
    required this.environment,
    required this.baseUrl,
    required this.enableLogging,
    required this.useMockAuth,
    required this.testOtp,
  });

  bool get isDev => environment == AppEnvironment.dev;

  // Android emulator uses 10.0.2.2 to reach host machine's localhost
  static const AppConfig dev = AppConfig(
    environment: AppEnvironment.dev,
    baseUrl: 'http://10.0.2.2:8001/api/v1',
    enableLogging: true,
    useMockAuth: false,
    testOtp: '123456',
  );

  static const AppConfig prod = AppConfig(
    environment: AppEnvironment.prod,
    baseUrl: 'https://your-backend-api.com/api/v1',
    enableLogging: false,
    useMockAuth: false,
    testOtp: '',
  );
}
