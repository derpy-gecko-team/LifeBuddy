import 'dart:convert';

abstract final class AuthValidators {
  static final _usernameRe = RegExp(r'^[A-Za-z0-9_]+$');
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? identifier(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Enter your username or email' : null;

  static String? username(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Choose a username';
    if (s.length < 3 || s.length > 20) return 'Use 3-20 characters';
    if (!_usernameRe.hasMatch(s)) return 'Only letters, numbers and underscores';
    return null;
  }

  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter your email';
    if (!_emailRe.hasMatch(s)) return 'Enter a valid email';
    return null;
  }

  /// At login we don't reveal or enforce password rules.
  static String? loginPassword(String? v) =>
      (v == null || v.isEmpty) ? 'Enter your password' : null;

  static String? newPassword(String? v) {
    if (v == null || v.isEmpty) return 'Choose a password';
    if (v.length < 8) return 'Use at least 8 characters';
    if (utf8.encode(v).length > 72) return 'Password is too long';
    return null;
  }
}