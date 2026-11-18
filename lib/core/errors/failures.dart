import 'package:equatable/equatable.dart';

/// Base failure class for domain-layer error handling.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Unable to reach the server. Please try again.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Unable to read local cached data.']);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed. Please check your credentials.',
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Showing offline data.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
