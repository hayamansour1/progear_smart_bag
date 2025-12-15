// lib/core/utils/validators.dart
import 'package:progear_smart_bag/core/utils/password_utils.dart';

class AppValidators {
  // Email
  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Please enter your email';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
    if (!ok) return 'Please enter a valid email';
    return null;
  }

  static String? password(String? v, {int minLen = 8}) {
    final value = v ?? '';
    if (value.isEmpty) return 'Please enter a password';

    final res = validatePassword(value, minLen: minLen);
    return res.isValid ? null : res.errors.first;
  }

  // Confirm Password
  static String? confirmPassword(String? v, String original) {
    final value = v ?? '';
    if (value.isEmpty) return 'Please confirm your password';
    if (value != original) return "Passwords don't match";
    return null;
  }
}
