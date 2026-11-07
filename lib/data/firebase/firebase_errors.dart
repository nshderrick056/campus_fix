import 'package:firebase_core/firebase_core.dart';

import '../repositories/repository_exception.dart';

/// Turns Firebase errors into [RepositoryException]s with messages that are
/// safe to show. Codes match the ones the fake backend uses.
RepositoryException mapFirebaseError(Object error) {
  if (error is RepositoryException) return error;
  if (error is FirebaseException) {
    return switch (error.code) {
      // Auth
      'invalid-email' => const RepositoryException(
          'invalid-email', 'That email address is not valid.'),
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' =>
        const RepositoryException(
            'wrong-credentials', 'Incorrect email or password.'),
      'user-disabled' => const RepositoryException(
          'user-disabled', 'This account has been disabled.'),
      'email-already-in-use' => const RepositoryException(
          'email-in-use', 'An account with this email already exists.'),
      'weak-password' => const RepositoryException(
          'weak-password', 'Choose a stronger password (at least 6 characters).'),
      'too-many-requests' => const RepositoryException('too-many-requests',
          'Too many attempts. Please wait a moment and try again.'),
      'requires-recent-login' => const RepositoryException(
          'requires-recent-login', 'Please sign in again to continue.'),
      'network-request-failed' || 'unavailable' || 'deadline-exceeded' =>
        const RepositoryException(
            'network', 'No connection. Check your internet and try again.'),
      // Firestore
      'permission-denied' => const RepositoryException(
          'permission-denied', 'You do not have permission to do that.'),
      'not-found' => const RepositoryException(
          'not-found', 'This report no longer exists.'),
      _ => RepositoryException(
          error.code, error.message ?? 'Something went wrong. Please try again.'),
    };
  }
  return const RepositoryException(
      'unknown', 'Something went wrong. Please try again.');
}

/// Runs [action] and rethrows any failure as a [RepositoryException].
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    throw mapFirebaseError(e);
  }
}
