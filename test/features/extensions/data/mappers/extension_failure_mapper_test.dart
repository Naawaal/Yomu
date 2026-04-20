import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/failure.dart';
import 'package:yomu/features/extensions/data/mappers/extension_failure_mapper.dart';
import 'package:yomu/features/extensions/data/repositories/bridge_extension_repository.dart';

void main() {
  group('ExtensionFailureMapper', () {
    test('maps MissingPluginException discovery failures to ServerFailure', () {
      final Failure failure = ExtensionFailureMapper.mapDiscovery(
        MissingPluginException('missing'),
      );

      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'Extension discovery is unavailable on this platform.',
      );
    });

    test('maps trust exceptions with code and trimmed message', () {
      final Failure failure = ExtensionFailureMapper.mapTrust(
        const ExtensionTrustException(
          code: 'TRUST_DENIED',
          message: '  Signer not allowed  ',
        ),
      );

      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'Extension trust failed (TRUST_DENIED): Signer not allowed',
      );
    });

    test('maps install requiresUserAction explicitly', () {
      final Failure failure = ExtensionFailureMapper.mapInstall(
        const ExtensionInstallException(
          code: ExtensionInstallErrorCode.requiresUserAction,
          message: '  Confirm on device  ',
        ),
      );

      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'Extension install requires user action (REQUIRES_USER_ACTION): Confirm on device',
      );
    });

    test('maps platform exceptions without a message to fallback text', () {
      final Failure failure = ExtensionFailureMapper.mapInstall(
        PlatformException(code: 'ERR'),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Extension install failed (ERR).');
    });
  });
}
