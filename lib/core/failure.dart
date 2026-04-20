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

/// Failure emitted for JSON parsing or deserialization errors.
final class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Failed to parse data']);
}

/// Stable source runtime error codes used for failure mapping.
abstract final class SourceFailureCode {
  static const String runtimeTimeout = 'RUNTIME_TIMEOUT';
  static const String runtimeCancelled = 'RUNTIME_CANCELLED';
  static const String runtimeExecutionFailed = 'RUNTIME_EXECUTION_FAILED';
  static const String sourceNotTrusted = 'SOURCE_NOT_TRUSTED';
  static const String unsupportedCapability = 'UNSUPPORTED_CAPABILITY';
  static const String missingPlugin = 'MISSING_PLUGIN';
  static const String unknown = 'UNKNOWN';
}

/// Base source-related failure carrying a stable machine-readable code.
sealed class SourceFailure extends Failure {
  const SourceFailure({required this.code, required String message})
    : super(message);

  final String code;

  @override
  List<Object?> get props => <Object?>[code, message];
}

/// Source runtime failure emitted for bridge/runtime execution errors.
final class SourceRuntimeFailure extends SourceFailure {
  const SourceRuntimeFailure({required super.code, required super.message});
}

/// Source trust failure emitted when source trust requirements are not met.
final class SourceTrustFailure extends SourceFailure {
  const SourceTrustFailure({required super.code, required super.message});
}

/// Source capability failure emitted when runtime capabilities are unavailable.
final class SourceCapabilityFailure extends SourceFailure {
  const SourceCapabilityFailure({required super.code, required super.message});
}
