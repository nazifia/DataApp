// App Constants

class AppConstants {
  // App Info
  static const String appName = 'TopUpNaija';
  static const String appVersion = '1.0.0';

  // API Base URL
  static const String baseUrl = 'https://your-backend-api.com/api/v1';

  // OTP Settings
  static const int otpExpiryMinutes = 2;
  static const int otpMaxAttempts = 3;

  // Wallet Limits
  static const double minWalletAmount = 100.0; // ₦100
  static const double maxWalletAmount = 500000.0; // ₦500,000

  // Transaction Limits
  static const double maxSingleTransaction = 100000.0; // ₦100,000
  static const double dailyTransactionLimit = 500000.0; // ₦500,000

  // Nigerian Telecom Networks
  static const List<String> supportedNetworks = [
    'MTN',
    'Airtel',
    'Glo',
    '9mobile'
  ];

  // Payment Gateways
  static const List<String> supportedPaymentGateways = [
    'Paystack',
    'Flutterwave',
    'Bank Transfer'
  ];

  // Animation Durations
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Padding Values
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border Radius
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
}