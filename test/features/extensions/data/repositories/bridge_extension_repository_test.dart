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
    this.installState = HostInstallState.committed,
  });

  final Set<String> capabilities;
  final List<HostExtensionPayload> extensions;
  final Object? trustThrows;
  final Object? installThrows;
  final HostInstallState installState;

  bool trustCalled = false;
  String? lastTrustedPackage;
  bool installCalled = false;
  String? lastInstalledPackage;
  String? lastInstallArtifact;

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
    lastInstallArtifact = installArtifact;
    return HostInstallResult(
      state: installState,
      message: installState == HostInstallState.committed
          ? 'Install session committed.'
          : 'Install requires user action.',
    );
  }

  @override
  Future<HostSourceRuntimePageResult> executeLatest({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return HostSourceRuntimePageResult(
      sourceId: sourceId,
      items: const <HostSourceMangaPayload>[],
      hasMore: false,
    );
  }

  @override
  Future<HostSourceRuntimePageResult> executePopular({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return HostSourceRuntimePageResult(
      sourceId: sourceId,
      items: const <HostSourceMangaPayload>[],
      hasMore: false,
    );
  }

  @override
  Future<HostSourceRuntimePageResult> executeSearch({
    required String sourceId,
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    return HostSourceRuntimePageResult(
      sourceId: sourceId,
      items: const <HostSourceMangaPayload>[],
      hasMore: false,
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

  @override
  Future<HostSourceRuntimePageResult> executeLatest({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) => Future.error(exception);

  @override
  Future<HostSourceRuntimePageResult> executePopular({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) => Future.error(exception);

  @override
  Future<HostSourceRuntimePageResult> executeSearch({
    required String sourceId,
    required String query,
    int page = 1,
    int pageSize = 20,
  }) => Future.error(exception);
}

/// A spy implementation of [ExtensionRepository] used as fallback.
class _SpyFallbackRepository implements ExtensionRepository {
  bool getAvailableCalled = false;
  bool trustCalled = false;
  String? lastTrustedPackage;
  bool installCalled = false;
  String? lastInstalledPackage;
  String? lastInstallArtifact;

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
    lastInstallArtifact = installArtifact;
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
  group('HostExtensionPayload.fromMap()', () {
    test('reads iconUrl from supported alias keys', () {
      final payloadFromIconUrl = HostExtensionPayload.fromMap(<String, Object?>{
        'name': 'MangaDex',
        'packageName': 'pkg.a',
        'iconUrl': 'https://repo.example/icon-a.png',
      });
      final payloadFromIconUri = HostExtensionPayload.fromMap(<String, Object?>{
        'name': 'NekoScans',
        'packageName': 'pkg.b',
        'iconUri': 'https://repo.example/icon-b.png',
      });
      final payloadFromSnakeCase =
          HostExtensionPayload.fromMap(<String, Object?>{
            'name': 'Comick',
            'packageName': 'pkg.c',
            'icon_url': 'https://repo.example/icon-c.png',
          });

      expect(payloadFromIconUrl.iconUrl, 'https://repo.example/icon-a.png');
      expect(payloadFromIconUri.iconUrl, 'https://repo.example/icon-b.png');
      expect(payloadFromSnakeCase.iconUrl, 'https://repo.example/icon-c.png');
    });

    test('returns null iconUrl for missing or empty values', () {
      final payloadWithoutIcon = HostExtensionPayload.fromMap(<String, Object?>{
        'name': 'No Icon',
        'packageName': 'pkg.none',
      });
      final payloadWithEmptyIcon = HostExtensionPayload.fromMap(
        <String, Object?>{
          'name': 'Empty Icon',
          'packageName': 'pkg.empty',
          'icon': '',
        },
      );

      expect(payloadWithoutIcon.iconUrl, isNull);
      expect(payloadWithEmptyIcon.iconUrl, isNull);
    });
  });

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
            'iconUrl': 'https://repo.example/mangadex.png',
          }),
        ],
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      final result = await repo.getAvailableExtensions();

      expect(result, hasLength(1));
      expect(result.first.name, 'MangaDex');
      expect(result.first.iconUrl, 'https://repo.example/mangadex.png');
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

    test(
      'throws typed trust exception on PlatformException from getRuntimeInfo',
      () async {
        final client = _ThrowingRuntimeHostClient(
          exception: PlatformException(code: 'ERR'),
        );
        final fallback = _SpyFallbackRepository();
        final repo = _makeRepo(client: client, fallback: fallback);

        await expectLater(
          repo.trust(packageName),
          throwsA(
            isA<ExtensionTrustException>().having(
              (ExtensionTrustException error) => error.code,
              'code',
              'ERR',
            ),
          ),
        );

        expect(fallback.trustCalled, isFalse);
      },
    );

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
    const resolvedArtifact =
        'https://repo.example/apk/eu.kanade.tachiyomi.extension.all.mangadex-v2.apk';

    test('calls native installExtension when capability present', () async {
      final stub = _StubHostClient(capabilities: _kFullCapabilities);
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await repo.install(packageName, installArtifact: resolvedArtifact);

      expect(stub.installCalled, isTrue);
      expect(stub.lastInstalledPackage, packageName);
      expect(stub.lastInstallArtifact, resolvedArtifact);
      expect(fallback.installCalled, isFalse);
    });

    test('delegates to fallback when install capability absent', () async {
      final stub = _StubHostClient(
        capabilities: {ExtensionsHostCapabilities.listAvailable},
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await repo.install(packageName, installArtifact: resolvedArtifact);

      expect(stub.installCalled, isFalse);
      expect(fallback.installCalled, isTrue);
      expect(fallback.lastInstalledPackage, packageName);
      expect(fallback.lastInstallArtifact, resolvedArtifact);
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

    test(
      'throws typed install exception on PlatformException from getRuntimeInfo',
      () async {
        final client = _ThrowingRuntimeHostClient(
          exception: PlatformException(code: 'ERR'),
        );
        final fallback = _SpyFallbackRepository();
        final repo = _makeRepo(client: client, fallback: fallback);

        await expectLater(
          repo.install(packageName),
          throwsA(
            isA<ExtensionInstallException>().having(
              (ExtensionInstallException error) => error.code,
              'code',
              'ERR',
            ),
          ),
        );

        expect(fallback.installCalled, isFalse);
      },
    );

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

    test('surfaces requiresUserAction as explicit pending error', () async {
      final stub = _StubHostClient(
        capabilities: _kFullCapabilities,
        installState: HostInstallState.requiresUserAction,
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await expectLater(
        repo.install(packageName, installArtifact: resolvedArtifact),
        throwsA(
          isA<ExtensionInstallException>()
              .having(
                (ExtensionInstallException error) => error.code,
                'code',
                ExtensionInstallErrorCode.requiresUserAction,
              )
              .having(
                (ExtensionInstallException error) => error.message,
                'message',
                'Install requires user action.',
              ),
        ),
      );

      expect(stub.installCalled, isTrue);
      expect(fallback.installCalled, isFalse);
    });

    test('treats PACKAGE_ALREADY_INSTALLED as success', () async {
      final stub = _StubHostClient(
        capabilities: _kFullCapabilities,
        installThrows: PlatformException(
          code: ExtensionInstallErrorCode.packageAlreadyInstalled,
          message: 'Extension already installed',
        ),
      );
      final fallback = _SpyFallbackRepository();
      final repo = _makeRepo(client: stub, fallback: fallback);

      await repo.install(packageName, installArtifact: resolvedArtifact);

      expect(stub.installCalled, isFalse);
      expect(fallback.installCalled, isFalse);
    });
  });
}
