/// Error thrown by any repository. [message] is safe to show to the user;
/// [code] is for logic (e.g. 'email-not-allowed', 'wrong-password',
/// 'permission-denied', 'not-found', 'network').
class RepositoryException implements Exception {
  const RepositoryException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'RepositoryException($code): $message';
}
