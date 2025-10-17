import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthFailure implements Exception {
  final String message;
  final String? code;
  AuthFailure(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ---------------- Basic ops ----------------
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _supabase.auth
          .signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      _debugLog(e);
      throw AuthFailure(_mapAuthError(e), code: e.code);
    } catch (e) {
      _debugLog(e);
      throw AuthFailure('Something went wrong. Please try again.');
    }
  }

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _supabase.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      _debugLog(e);
      throw AuthFailure(_mapAuthError(e), code: e.code);
    } catch (e) {
      _debugLog(e);
      throw AuthFailure('Something went wrong. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      _debugLog(e);
      throw AuthFailure(_mapAuthError(e));
    } catch (e) {
      _debugLog(e);
      throw AuthFailure('Failed to sign out. Please try again.');
    }
  }

  // ---------------- Helpers / Queries ----------------
  String? getCurrentUserEmail() => _supabase.auth.currentUser?.email;

  User? get currentUser => _supabase.auth.currentUser;

  bool get isSignedIn => _supabase.auth.currentUser != null;

  bool get isEmailVerified =>
      _supabase.auth.currentUser?.emailConfirmedAt != null;

  Stream<Session?> authSessionStream() =>
      _supabase.auth.onAuthStateChange.map((e) => e.session);

  Future<void> sendPasswordReset(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo:
            'https://hayamansour1.github.io/progear_smart_bag/reset-password.html',
      );
    } on AuthException catch (e) {
      _debugLog(e);
      throw AuthFailure(_mapAuthError(e), code: e.code);
    } catch (e) {
      _debugLog(e);
      throw AuthFailure('Could not send reset email. Please try again.');
    }
  }

  /// يحدّث كلمة المرور للمستخدم الحالي (يتطلب جلسة صالحة).
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      _debugLog(e);
      throw AuthFailure(_mapAuthError(e), code: e.code);
    } catch (e) {
      _debugLog(e);
      throw AuthFailure('Failed to update password. Please try again.');
    }
  }

  // ---------------- Error mapping ----------------
  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = (e.code ?? '').toLowerCase();

    int? status;
    if (e is AuthApiException) {
      status = int.tryParse(e.statusCode ?? '');
    }

    if (code == 'invalid_credentials' ||
        msg.contains('invalid login') ||
        msg.contains('invalid credentials')) {
      return 'Email or password is incorrect.';
    }

    if (msg.contains('email not confirmed') ||
        code == 'email_not_confirmed' ||
        msg.contains('email confirmation required')) {
      return 'Please verify your email, then try again.';
    }

    if (msg.contains('user not found') || code == 'user_not_found') {
      return 'No account found for this email.';
    }

    if (msg.contains('already registered') ||
        msg.contains('already exists') ||
        code == 'user_already_exists') {
      return 'This email is already registered.';
    }

    if (msg.contains('weak password') ||
        msg.contains('password should be') ||
        code == 'weak_password') {
      return 'Password is too weak. Please use a stronger one.';
    }

    if (msg.contains('invalid email') || code == 'invalid_email') {
      return 'Please enter a valid email address.';
    }

    if (msg.contains('rate limit') ||
        msg.contains('too many requests') ||
        code == 'over_email_send_rate_limit' ||
        status == 429) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    if (msg.contains('network') ||
        msg.contains('timeout') ||
        (status != null && status >= 500)) {
      return 'Network issue. Please check your connection and try again.';
    }

    return 'Authentication failed. Please try again.';
  }

  void _debugLog(Object e) {
    if (kDebugMode) debugPrint('[AuthService] $e');
  }
}
