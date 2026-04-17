import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/bridge/extensions_host_client.dart';
import 'package:yomu/features/extensions/data/repositories/bridge_extension_repository.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/domain/repositories/extension_repository.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

/// A configurable stub for [ExtensionsHostClient] that tracks calls.
class _StubHostClient implements ExtensionsHostClient {
  _StubHostClient({
    required this.capabilities,
    this.extensions = const [],
    this.trustThrows,
    this.installThrows,
  });

  final Set<String> capabilities;
  final List<HostExtensionPayload> extensions;
  final Object? trustThrows;
  final Object? installThrows;

  bool trustCalled = false;
  String? lastTrustedPackage;
  bool installCalled = false;
  String? lastInstalledPackage;

  @override
  Future<ExtensionsHostRuntimeInfo> getRuntimeInfo() async =>
      ExtensionsHostRuntimeInfo(schemaVersion: 1, capabilities: capabilities);

  @override
  Future<List<HostExtensionPayload>> listAvailableExtensions() async =>
      extensions;

  @override
  Future<void> trustExtension(String packageName) async {
    if (trustThrows != null) throw trustThrows!;
    trustCalled = true;
    lastTrustedPackage = packageName;
  }

  @override
  Future<HostInstallResult> installExtension(
    String packageName, {
    String? installArtifact,
  }) async {
    if (installThrows != null) throw installThrows!;
    installCalled = true;
    lastInstalledPackage = packageName;
    return const HostInstallResult(
      state: HostInstallState.committed,
      message: 'Install session committed.',
    );
  }
}

/// A [ExtensionsHostClient] whose [getRuntimeInfo] throws on every call.
class _ThrowingRuntimeHostClient implements ExtensionsHostClient {
  const _ThrowingRuntimeHostClient({required this.exception});

  final Object exception;

  @override
  Future<ExtensionsHostRuntimeInfo> getRuntimeInfo() => Future.error(exception);

  @override
  Future<List<HostExtensionPayload>> listAvailableExtensions() =>
      Future.error(exception);

  @override
  Future<void> trustExtension(String packageName) => Future.error(exception);

  @override
  Future<HostInstallResult> installExtension(
    String packageName, {
    String? installArtifact,
  }) => Future.error(exception);
}

/// A spy implementation of [ExtensionRepository] used as fallback.
class _SpyFallbackRepository implements ExtensionRepository {
  bool getAvailableCalled = false;
  bool trustCalled = false;
  String? lastTrustedPackage;
  bool installCalled = false;
  String? lastInstalledPackage;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async {
    getAvailableCalled = true;
    return const [];
  }

  @override
  Future<void> trust(String packageName) async {
    trustCalled = true;
    lastTrustedPackage = packageName;
  }

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {
    installCalled = true;
    lastInstalledPackage = packageName;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

BridgeExtensionRepository _makeRepo({
  required ExtensionsHostClient client,
  required _SpyFallbackRepository fallback,
}) =>
    BridgeExtensionRepository(hostClient: client, fallbackRepository: fallback);

const _kFullCapabilities = {
  ExtensionsHostCapabilities.listAvailable,
  ExtensionsHostCapabilities.trust,
  ExtensionsHostCapabilities.install,
};

const _kNoCapabilities = <String>{};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BridgeExtensionRepository.getAvailableExtensions()', () {
    test('uses native path when extensions.list capability present', () async {
      final stub = _StubHostClient(
        capabilities: _kFullCapabilities,
        extensions: [
          HostExtensionPayload.fromMap({
            'name': 'MangaDex',
            'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
            'language': 'all',
            'versionName': '1.0.0',
            'hasUpdate': false,
            'isNsfw': false,
            'isTrusted': true,
          }),
        ],
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      final result = await repo.getAvailableExtensions();

      expect(result, hasLength(1));
      expect(result.first.name, 'MangaDex');
      expect(fallback.getAvailableCalled, isFalse);
    });

    test(
      'falls back when capabilities are non-empty and list is absent',
      () async {
        final stub = _StubHostClient(
          capabilities: {ExtensionsHostCapabilities.trust},
        );
        final fallback = _SpyFallbackRepository();
        final repo = _makeRepo(client: stub, fallback: fallback);

        await repo.getAvailableExtensions();

        expect(fallback.getAvailableCalled, isTrue);
      },
    );

    test(
      'uses native path when capabilities set is empty (backward compat)',
      () async {
        final stub = _StubHostClient(capabilities: _kNoCapabilities);
        final fallback = _SpyFallbackRepository();
        final repo = _makeRepo(client: stub, fallback: fallback);

        await repo.getAvailableExtensions();

        expect(fallback.getAvailableCalled, isFalse);
      },
    );

    test('uses legacy capabilities alias for list', () async {
      final stub = _StubHostClient(
        capabilities: {ExtensionsHostCapabilities.legacyListAvailable},
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await repo.getAvailableExtensions();

      expect(fallback.getAvailableCalled, isFalse);
    });

    test('falls back on MissingPluginException', () async {
      final client = _ThrowingRuntimeHostClient(
        exception: MissingPluginException('no plugin'),
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: client, fallback: fallback);

      await repo.getAvailableExtensions();

      expect(fallback.getAvailableCalled, isTrue);
    });

    test('falls back on PlatformException', () async {
      final client = _ThrowingRuntimeHostClient(
        exception: PlatformException(code: 'ERR'),
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: client, fallback: fallback);

      await repo.getAvailableExtensions();

      expect(fallback.getAvailableCalled, isTrue);
    });
  });

  // -------------------------------------------------------------------------

  group('BridgeExtensionRepository.trust()', () {
    const packageName = 'eu.kanade.tachiyomi.extension.all.mangadex';

    test('calls native trustExtension when capability present', () async {
      final stub = _StubHostClient(capabilities: _kFullCapabilities);
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await repo.trust(packageName);

      expect(stub.trustCalled, isTrue);
      expect(stub.lastTrustedPackage, packageName);
      expect(fallback.trustCalled, isFalse);
    });

    test('delegates to fallback when trust capability absent', () async {
      final stub = _StubHostClient(
        capabilities: {ExtensionsHostCapabilities.listAvailable},
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await repo.trust(packageName);

      expect(stub.trustCalled, isFalse);
      expect(fallback.trustCalled, isTrue);
      expect(fallback.lastTrustedPackage, packageName);
    });

    test('uses native when capabilities empty (backward compat)', () async {
      final stub = _StubHostClient(capabilities: _kNoCapabilities);
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await repo.trust(packageName);

      expect(stub.trustCalled, isTrue);
      expect(fallback.trustCalled, isFalse);
    });

    test('falls back on MissingPluginException from getRuntimeInfo', () async {
      final client = _ThrowingRuntimeHostClient(
        exception: MissingPluginException('no plugin'),
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: client, fallback: fallback);

      await repo.trust(packageName);

      expect(fallback.trustCalled, isTrue);
      expect(fallback.lastTrustedPackage, packageName);
    });

    test('falls back on PlatformException from getRuntimeInfo', () async {
      final client = _ThrowingRuntimeHostClient(
        exception: PlatformException(code: 'ERR'),
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: client, fallback: fallback);

      await repo.trust(packageName);

      expect(fallback.trustCalled, isTrue);
    });

    test(
      'throws typed trust exception on PlatformException from trustExtension',
      () async {
        final stub = _StubHostClient(
          capabilities: _kFullCapabilities,
          trustThrows: PlatformException(
            code: 'SIGNATURE_VERIFICATION_FAILED',
            message:
                'Package signer does not match the host signer or configured signer allowlist.',
          ),
        );
        final fallback = _SpyFallbackRepository();
        final repo = _makeRepo(client: stub, fallback: fallback);

        await expectLater(
          repo.trust(packageName),
          throwsA(
            isA<ExtensionTrustException>()
                .having(
                  (ExtensionTrustException error) => error.code,
                  'code',
                  'SIGNATURE_VERIFICATION_FAILED',
                )
                .having(
                  (ExtensionTrustException error) => error.message,
                  'message',
                  'Package signer does not match the host signer or configured signer allowlist.',
                ),
          ),
        );

        expect(fallback.trustCalled, isFalse);
      },
    );
  });

  // -------------------------------------------------------------------------

  group('BridgeExtensionRepository.install()', () {
    const packageName = 'eu.kanade.tachiyomi.extension.all.mangadex';

    test('calls native installExtension when capability present', () async {
      final stub = _StubHostClient(capabilities: _kFullCapabilities);
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await repo.install(packageName);

      expect(stub.installCalled, isTrue);
      expect(stub.lastInstalledPackage, packageName);
      expect(fallback.installCalled, isFalse);
    });

    test('delegates to fallback when install capability absent', () async {
      final stub = _StubHostClient(
        capabilities: {ExtensionsHostCapabilities.listAvailable},
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await repo.install(packageName);

      expect(stub.installCalled, isFalse);
      expect(fallback.installCalled, isTrue);
      expect(fallback.lastInstalledPackage, packageName);
    });

    test('uses native when capabilities empty (backward compat)', () async {
      final stub = _StubHostClient(capabilities: _kNoCapabilities);
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await repo.install(packageName);

      expect(stub.installCalled, isTrue);
      expect(fallback.installCalled, isFalse);
    });

    test('falls back on MissingPluginException from getRuntimeInfo', () async {
      final client = _ThrowingRuntimeHostClient(
        exception: MissingPluginException('no plugin'),
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: client, fallback: fallback);

      await repo.install(packageName);

      expect(fallback.installCalled, isTrue);
      expect(fallback.lastInstalledPackage, packageName);
    });

    test('falls back on PlatformException from getRuntimeInfo', () async {
      final client = _ThrowingRuntimeHostClient(
        exception: PlatformException(code: 'ERR'),
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: client, fallback: fallback);

      await repo.install(packageName);

      expect(fallback.installCalled, isTrue);
    });

    test(
      'throws typed install exception on PlatformException from installExtension',
      () async {
        final stub = _StubHostClient(
          capabilities: _kFullCapabilities,
          installThrows: PlatformException(code: 'INSTALL_ERR'),
        );
        final fallback = _SpyFallbackRepository();
        final repo = _makeRepo(client: stub, fallback: fallback);

        await expectLater(
          repo.install(packageName),
          throwsA(
            isA<ExtensionInstallException>().having(
              (ExtensionInstallException error) => error.code,
              'code',
              'INSTALL_ERR',
            ),
          ),
        );

        expect(fallback.installCalled, isFalse);
      },
    );
  });
}
