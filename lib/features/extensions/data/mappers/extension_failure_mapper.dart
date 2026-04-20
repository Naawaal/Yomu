import 'package:flutter/services.dart';

import '../../../../core/failure.dart';
import '../repositories/bridge_extension_repository.dart';

/// Normalizes extension bridge/runtime failures into typed failures.
abstract final class ExtensionFailureMapper {
  /// Maps discovery/list failures.
  static Failure mapDiscovery(Object error) {
    return _map(
      error,
      operation: 'Extension discovery failed',
      unavailableMessage:
          'Extension discovery is unavailable on this platform.',
    );
  }

  /// Maps trust failures.
  static Failure mapTrust(Object error) {
    return _map(
      error,
      operation: 'Extension trust failed',
      unavailableMessage: 'Extension trust is unavailable on this platform.',
    );
  }

  /// Maps install failures.
  static Failure mapInstall(Object error) {
    return _map(
      error,
      operation: 'Extension install failed',
      unavailableMessage: 'Extension install is unavailable on this platform.',
      userActionOperation: 'Extension install requires user action',
    );
  }

  static Failure _map(
    Object error, {
    required String operation,
    required String unavailableMessage,
    String? userActionOperation,
  }) {
    if (error is MissingPluginException) {
      return ServerFailure(unavailableMessage);
    }

    if (error is ExtensionTrustException) {
      return ServerFailure(
        _formatFailureMessage(operation, error.code, error.message),
      );
    }

    if (error is ExtensionInstallException) {
      final String installOperation =
          error.code == ExtensionInstallErrorCode.requiresUserAction &&
              userActionOperation != null
          ? userActionOperation
          : operation;

      return ServerFailure(
        _formatFailureMessage(installOperation, error.code, error.message),
      );
    }

    if (error is PlatformException) {
      return ServerFailure(
        _formatFailureMessage(operation, error.code, error.message),
      );
    }

    return ServerFailure('$operation: $error');
  }

  static String _formatFailureMessage(
    String operation,
    String code,
    String? message,
  ) {
    final String trimmedMessage = message?.trim() ?? '';
    if (trimmedMessage.isEmpty) {
      return '$operation ($code).';
    }

    return '$operation ($code): $trimmedMessage';
  }
}
