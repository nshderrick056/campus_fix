import '../constants/app_constants.dart';

/// Form validators. Each returns an error message, or null when valid.
abstract final class Validators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? aluEmail(String? value) {
    final v = value?.trim().toLowerCase() ?? '';
    if (v.isEmpty) return 'Enter your ALU email';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    final domain = v.split('@').last;
    if (domain != AppConstants.studentEmailDomain && domain != AppConstants.staffEmailDomain) {
      return 'Only @${AppConstants.studentEmailDomain} or @${AppConstants.staffEmailDomain} emails are accepted';
    }
    return null;
  }

  static String? loginPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Enter your password' : null;

  static bool hasMinLength(String v) => v.length >= 8;
  static bool hasNumber(String v) => v.contains(RegExp(r'\d'));

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (!hasMinLength(v)) return 'Use at least 8 characters';
    if (!hasNumber(v)) return 'Include at least one number';
    return null;
  }

  static String? confirmPassword(String? value, String password) =>
      value != password ? 'Passwords do not match' : null;

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your full name';
    if (v.length < 3) return 'Name is too short';
    return null;
  }

  static const titleMax = 80;
  static const descriptionMax = 500;

  static String? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Give the issue a short title';
    if (v.length < 5) return 'Title must be at least 5 characters';
    if (v.length > titleMax) return 'Keep the title under $titleMax characters';
    return null;
  }

  static String? description(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Describe what happened';
    if (v.length < 15) return 'Add a little more detail (at least 15 characters)';
    if (v.length > descriptionMax) return 'Keep it under $descriptionMax characters';
    return null;
  }

  static String? location(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Choose where the issue is' : null;
}
