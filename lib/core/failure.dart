import 'package:equatable/equatable.dart';

/// Base type for recoverable domain/data failures.
sealed class Failure extends Equatable {
  const Failure([this.message = 'An unexpected error occurred']);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// Failure emitted for remote/server-side errors.
final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

/// Failure emitted for local cache-related errors.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

/// Failure emitted when network connectivity is unavailable.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}
