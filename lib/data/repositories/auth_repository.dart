import '../../models/app_user.dart';

/// Authentication + the user's profile. All methods throw
/// [RepositoryException] with a user-friendly message on failure.
abstract interface class AuthRepository {
  /// Emits the current user (null when signed out). Emits again after
  /// sign-in, sign-out, and [reloadUser].
  Stream<AppUser?> watchUser();

  AppUser? get currentUser;

  /// Rejects emails outside the ALU domains with code 'email-not-allowed'.
  Future<void> signIn({required String email, required String password});

  /// Creates the auth account and `users/{uid}` (role is always student),
  /// then sends the verification email.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  /// Signs in with a Google account, which must be an ALU email (code
  /// 'email-not-allowed' otherwise). Creates the student profile on first
  /// sign-in. Google accounts are already verified. Code 'cancelled' if the
  /// user closes the Google window.
  Future<void> signInWithGoogle();

  Future<void> sendVerificationEmail();

  /// Reloads the auth user (e.g. after they tap the email link) and
  /// re-emits on [watchUser]. Returns whether the email is now verified.
  Future<bool> reloadUser();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
