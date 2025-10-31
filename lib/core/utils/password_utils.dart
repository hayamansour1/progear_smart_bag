// lib/core/utils/password_utils.dart
enum PasswordStrength { weak, fair, good, strong }

class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final PasswordStrength strength;

  const PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.strength,
  });
}

/// Roles:
/// - Length >= 8
/// - smletter  +  caletter + number + sympol
PasswordValidationResult validatePassword(String value, {int minLen = 8}) {
  final v = value;
  final errors = <String>[];

  final hasMin = v.length >= minLen;
  final hasLower = RegExp(r'[a-z]').hasMatch(v);
  final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
  final hasDigit = RegExp(r'\d').hasMatch(v);
  final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\[\]\\;/+=~`]').hasMatch(v);

  if (!hasMin) errors.add('Use at least $minLen characters');
  if (!hasLower) errors.add('Add a lowercase letter');
  if (!hasUpper) errors.add('Add an uppercase letter');
  if (!hasDigit) errors.add('Add a number');
  if (!hasSpecial) errors.add('Add a special character');

  int score = 0;
  if (hasMin) score++;
  if (hasLower && hasUpper) score++;
  if (hasDigit) score++;
  if (hasSpecial) score++;

  final strength = switch (score) {
    <= 1 => PasswordStrength.weak,
    2 => PasswordStrength.fair,
    3 => PasswordStrength.good,
    _ => PasswordStrength.strong,
  };

  return PasswordValidationResult(
    isValid: errors.isEmpty,
    errors: errors,
    strength: strength,
  );
}

String strengthLabel(PasswordStrength s) => switch (s) {
      PasswordStrength.weak => 'Weak',
      PasswordStrength.fair => 'Fair',
      PasswordStrength.good => 'Good',
      PasswordStrength.strong => 'Strong',
    };
