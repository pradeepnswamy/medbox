import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

/// Thin wrapper around [FirebaseAuth] that exposes only what MedBox needs.
///
/// All methods surface [FirebaseAuthException] directly — callers are
/// responsible for mapping codes to user-facing messages.
class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;

  // ── State ─────────────────────────────────────────────────────────────────

  /// Currently signed-in user, or null.
  static User? get currentUser => _auth.currentUser;

  /// Stream that emits whenever the auth state changes (sign-in / sign-out).
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign-in ───────────────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  /// Throws [FirebaseAuthException] on failure.
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  // ── Sign-up ───────────────────────────────────────────────────────────────

  /// Creates a new account and updates the user's display name.
  /// Throws [FirebaseAuthException] on failure.
  static Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Store display name so it's available everywhere via currentUser.displayName.
    await cred.user?.updateDisplayName(name.trim());
    return cred;
  }

  // ── Password reset ────────────────────────────────────────────────────────

  /// Sends a password-reset e-mail to [email].
  static Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Sign-out ──────────────────────────────────────────────────────────────

  /// Signs out the current user and clears all pending notifications.
  static Future<void> signOut() async {
    // Remove scheduled notifications before signing out so a different user
    // logging into the same device doesn't see stale alerts.
    await NotificationService.cancelAll();
    await _auth.signOut();
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  /// Returns a friendly message for common [FirebaseAuthException] codes.
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
