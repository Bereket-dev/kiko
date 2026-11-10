import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Custom exceptions
// ─────────────────────────────────────────────────────────────────────────────

/// General Firebase Auth wrapper exception.
class CloudAuthException implements Exception {
  final String message;
  final String? code;

  const CloudAuthException(this.message, {this.code});

  @override
  String toString() => code != null
      ? 'CloudAuthException[$code]: $message'
      : 'CloudAuthException: $message';
}

/// Thrown by [CloudAuthService.deleteAccount] when the user needs to
/// re-authenticate before the operation can proceed.
class ReauthRequiredException implements Exception {
  const ReauthRequiredException();

  @override
  String toString() =>
      'ReauthRequiredException: re-authentication required before account deletion';
}

// ─────────────────────────────────────────────────────────────────────────────
// CloudAuthService
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [FirebaseAuth] with application-level error handling and enforces
/// email-verification before sign-in succeeds.
class CloudAuthService {
  CloudAuthService() : _auth = FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // ── Accessors ──────────────────────────────────────────────────────────────

  /// The currently signed-in Firebase user, or `null` if no session exists.
  User? get currentUser => _auth.currentUser;

  /// A stream that emits a [User] on sign-in and `null` on sign-out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// `true` if there is a current user and their email address is verified.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ── Authentication ─────────────────────────────────────────────────────────

  /// Creates a new Firebase Auth account with [email] and [password], then
  /// immediately sends an email-verification message to the new address.
  ///
  /// Throws [CloudAuthException] on any [FirebaseAuthException].
  Future<void> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Best-effort: send verification email right away; ignore transient
      // failures — the user can request another via [sendVerificationEmail].
      await credential.user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw CloudAuthException(e.message ?? 'Sign-up failed', code: e.code);
    }
  }

  /// Signs in with [email] and [password].
  ///
  /// Throws [CloudAuthException] with code `'email-not-verified'` if the
  /// account exists but the email address has not been verified yet (signing
  /// out immediately in that case so no partial session is left).
  ///
  /// Throws [CloudAuthException] on any other [FirebaseAuthException].
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw CloudAuthException(e.message ?? 'Sign-in failed', code: e.code);
    }

    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await _auth.signOut();
      throw const CloudAuthException(
        'Email address has not been verified. '
        'Please check your inbox and verify before signing in.',
        code: 'email-not-verified',
      );
    }
  }

  // ── Verification & password reset ──────────────────────────────────────────

  /// Sends (or re-sends) an email-verification link to the current user's
  /// address.
  ///
  /// Throws [CloudAuthException] if there is no current user, or on a
  /// [FirebaseAuthException].
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const CloudAuthException(
        'No signed-in user to send verification email to.',
        code: 'no-current-user',
      );
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw CloudAuthException(
        e.message ?? 'Failed to send verification email',
        code: e.code,
      );
    }
  }

  /// Sends a password-reset email to [email].
  ///
  /// Throws [CloudAuthException] on any [FirebaseAuthException].
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw CloudAuthException(
        e.message ?? 'Failed to send password reset email',
        code: e.code,
      );
    }
  }

  // ── Session management ─────────────────────────────────────────────────────

  /// Signs the current user out of Firebase.
  ///
  /// Throws [CloudAuthException] on any [FirebaseAuthException].
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw CloudAuthException(e.message ?? 'Sign-out failed', code: e.code);
    }
  }

  // ── Account deletion ───────────────────────────────────────────────────────

  /// Permanently deletes the current Firebase Auth account.
  ///
  /// If Firebase returns a `requires-recent-login` error, throws
  /// [ReauthRequiredException] so the caller can prompt the user to sign in
  /// again before retrying.
  ///
  /// Throws [CloudAuthException] on other [FirebaseAuthException]s.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const CloudAuthException(
        'No signed-in user to delete.',
        code: 'no-current-user',
      );
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const ReauthRequiredException();
      }
      throw CloudAuthException(
        e.message ?? 'Account deletion failed',
        code: e.code,
      );
    }
  }
}
