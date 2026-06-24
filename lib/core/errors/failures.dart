import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure originating from the authentication layer.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Failure originating from a network or server error.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure from local cache or encrypted storage operations.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure when a transaction cannot be validated or queued.
class TransactionFailure extends Failure {
  const TransactionFailure(super.message);
}
