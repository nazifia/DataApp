// Validation Utilities
import 'package:intl/intl.dart';

class Validators {
  // Nigerian Phone Number Validation
  // Accepts: 0XXXXXXXXXX, +234XXXXXXXXX, 234XXXXXXXXX, or 10-digit [789]XXXXXXXXX
  static bool isValidNigerianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-+]'), '');
    return RegExp(r'^(0[789]\d{9}|234[789]\d{9}|[789]\d{9})$').hasMatch(cleaned);
  }

  // Normalize a Nigerian phone number to local format (0XXXXXXXXXX).
  // Accepts: 0XXXXXXXXXX, +234XXXXXXXXX, 234XXXXXXXXX, or 10-digit [789]XXXXXXXXX.
  static String formatNigerianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-+]'), '');

    if (cleaned.startsWith('234') && cleaned.length == 13) {
      // 2348031234567 → 08031234567
      return '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('0')) {
      // Already local format
      return cleaned;
    } else if (RegExp(r'^[789]\d{9}$').hasMatch(cleaned)) {
      // 10-digit subscriber format: 8031234567 → 08031234567
      return '0$cleaned';
    }

    return phone; // Return original if unrecognised
  }

  // Validate Amount
  static bool isValidAmount(String amount) {
    if (amount.isEmpty) return false;

    final regex = RegExp(r'^\d+(\.\d{1,2})?$');
    return regex.hasMatch(amount);
  }

  // Validate OTP
  static bool isValidOtp(String otp) {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(otp);
  }
}

// Currency Formatting
class CurrencyFormatter {
  static final NumberFormat _nairaFormat =
      NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2);
  static final NumberFormat _nairaWholeFormat =
      NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

  /// Formats a Naira amount, dropping decimals when the amount is a whole number.
  static String formatNaira(double amount) {
    if (amount == amount.truncateToDouble()) {
      return _nairaWholeFormat.format(amount);
    }
    return _nairaFormat.format(amount);
  }

  /// Compact human-friendly format: ₦1.5K, ₦2.3M etc.
  static String formatNairaCompact(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      final s = m == m.truncateToDouble() ? m.toInt().toString() : m.toStringAsFixed(1);
      return '₦${s}M';
    }
    if (amount >= 1000) {
      final k = amount / 1000;
      final s = k == k.truncateToDouble() ? k.toInt().toString() : k.toStringAsFixed(1);
      return '₦${s}K';
    }
    return formatNaira(amount);
  }

  static double parseNaira(String amount) {
    // Remove currency symbol and commas
    final cleaned = amount.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}

// Date Formatting
class DateFormatter {
  static final DateFormat _displayFormat =
      DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat _shortFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String formatDateTime(DateTime dateTime) {
    return _displayFormat.format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return _shortFormat.format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }
}

// Device Information Utilities
class DeviceUtils {
  static String generateDeviceId() {
    // In a real app, you would use device_info_plus to get unique device ID
    // For now, we'll use a placeholder
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }
}