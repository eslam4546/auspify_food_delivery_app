/// Thrown when a remote API or cloud backend call fails.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error occurred.']);

  final String message;

  @override
  String toString() => 'ServerException: $message';
}

/// Thrown when reading or writing local Hive cache fails.
class CacheException implements Exception {
  const CacheException([this.message = 'Local storage error occurred.']);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

/// Thrown when Firebase Authentication or Google Sign-In fails.
class AuthException implements Exception {
  const AuthException([this.message = 'Authentication error occurred.']);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
