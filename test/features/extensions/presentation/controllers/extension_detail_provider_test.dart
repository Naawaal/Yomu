import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/bridge/extensions_host_client.dart';
import 'package:yomu/features/extensions/data/repositories/bridge_extension_repository.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/domain/repositories/extension_repository.dart';
import 'package:yomu/features/extensions/presentation/controllers/extension_detail_provider.dart';
import 'package:yomu/features/extensions/presentation/controllers/extensions_controllers.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

class _FakeHostClient implements ExtensionsHostClient {
  const _FakeHostClient({required this.items});

  final List<ExtensionItem> items;

  @override
  Future<ExtensionsHostRuntimeInfo> getRuntimeInfo() async =>
      ExtensionsHostRuntimeInfo(
        schemaVersion: 1,
        capabilities: {ExtensionsHostCapabilities.listAvailable},
      );

  @override
  Future<List<HostExtensionPayload>> listAvailableExtensions() async => items
      .map(
        (ExtensionItem e) => HostExtensionPayload.fromMap({
          'name': e.name,
          'packageName': e.packageName,
          'language': e.language,
          'versionName': e.versionName,
          'hasUpdate': e.hasUpdate,
          'isNsfw': e.isNsfw,
          'isTrusted': e.trustStatus == ExtensionTrustStatus.trusted,
        }),
      )
      .toList();

  @override
  Future<void> trustExtension(String packageName) async {}

  @override
  Future<HostInstallResult> installExtension(
    String packageName, {
    String? installArtifact,
  }) async {
    return const HostInstallResult(
      state: HostInstallState.committed,
      message: 'Install session committed.',
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

class _StaticFallback implements ExtensionRepository {
  const _StaticFallback({required this.items});

  final List<ExtensionItem> items;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async => items;

  @override
  Future<void> trust(String packageName) async {}

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const ExtensionItem _mangadex = ExtensionItem(
  name: 'MangaDex',
  packageName: 'eu.kanade.tachiyomi.extension.all.mangadex',
  language: 'all',
  versionName: '1.4.9',
  isInstalled: true,
  hasUpdate: true,
  isNsfw: false,
  trustStatus: ExtensionTrustStatus.trusted,
);

const ExtensionItem _nsfw = ExtensionItem(
  name: 'NekoScans',
  packageName: 'eu.kanade.tachiyomi.extension.all.nekoscans',
  language: 'all',
  versionName: '1.4.5',
  isInstalled: true,
  hasUpdate: false,
  isNsfw: true,
  trustStatus: ExtensionTrustStatus.untrusted,
);

ProviderContainer _makeContainer(List<ExtensionItem> items) {
  final container = ProviderContainer(
    overrides: [
      extensionRepositoryProvider.overrideWithValue(
        BridgeExtensionRepository(
          hostClient: _FakeHostClient(items: items),
          fallbackRepository: _StaticFallback(items: items),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('extensionDetailProvider derivation', () {
    test('returns found item when packageName matches', () async {
      final container = _makeContainer([_mangadex, _nsfw]);

      // Allow list to load
      await container.read(extensionsListControllerProvider.future);

      final AsyncValue<ExtensionItem?> detail = container.read(
        extensionDetailProvider(_mangadex.packageName),
      );

      expect(detail.hasValue, isTrue);
      expect(detail.value?.packageName, _mangadex.packageName);
      expect(detail.value?.name, _mangadex.name);
    });

    test('returns found item with correct packageName', () async {
      final container = _makeContainer([_mangadex, _nsfw]);

      await container.read(extensionsListControllerProvider.future);

      final AsyncValue<ExtensionItem?> detail = container.read(
        extensionDetailProvider(_mangadex.packageName),
      );

      expect(detail.value?.packageName, _mangadex.packageName);
      expect(detail.value?.name, _mangadex.name);
    });

    test('returns null when packageName not in list', () async {
      final container = _makeContainer([_mangadex]);

      await container.read(extensionsListControllerProvider.future);

      final AsyncValue<ExtensionItem?> detail = container.read(
        extensionDetailProvider('com.unknown.package'),
      );

      expect(detail.value, isNull);
    });

    test('reflects loading state while list is loading', () {
      final container = _makeContainer([_mangadex]);

      // Read detail before awaiting list
      final AsyncValue<ExtensionItem?> detail = container.read(
        extensionDetailProvider(_mangadex.packageName),
      );

      expect(detail.isLoading, isTrue);
    });

    test('reflects error state when list fails', () async {
      // Force list error by using a throwing host with no fallback items
      final container = ProviderContainer(
        overrides: [
          extensionRepositoryProvider.overrideWithValue(
            BridgeExtensionRepository(
              hostClient: _ThrowingHostClient(),
              fallbackRepository: const _StaticFallback(items: []),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Await the list future so the derived provider settles
      await container.read(extensionsListControllerProvider.future);

      final AsyncValue<ExtensionItem?> detail = container.read(
        extensionDetailProvider('any.package'),
      );

      // The derived provider should propagate data (empty list → null) from fallback
      expect(detail.hasValue, isTrue);
      expect(
        detail.value,
        isNull,
        reason: 'Fallback returns empty list → no match → null',
      );
    });

    test(
      'returns different items for different packageName arguments',
      () async {
        final container = _makeContainer([_mangadex, _nsfw]);

        await container.read(extensionsListControllerProvider.future);

        final AsyncValue<ExtensionItem?> detail1 = container.read(
          extensionDetailProvider(_mangadex.packageName),
        );
        final AsyncValue<ExtensionItem?> detail2 = container.read(
          extensionDetailProvider(_nsfw.packageName),
        );

        expect(detail1.value?.name, 'MangaDex');
        expect(detail2.value?.name, 'NekoScans');
      },
    );
  });
}

class _ThrowingHostClient implements ExtensionsHostClient {
  @override
  Future<ExtensionsHostRuntimeInfo> getRuntimeInfo() =>
      Future.error(PlatformException(code: 'ERR', message: 'fail'));

  @override
  Future<List<HostExtensionPayload>> listAvailableExtensions() =>
      Future.error(PlatformException(code: 'ERR'));

  @override
  Future<void> trustExtension(String packageName) =>
      Future.error(PlatformException(code: 'ERR'));

  @override
  Future<HostInstallResult> installExtension(
    String packageName, {
    String? installArtifact,
  }) => Future.error(PlatformException(code: 'ERR'));

  @override
  Future<HostSourceRuntimePageResult> executeLatest({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) => Future.error(PlatformException(code: 'ERR'));

  @override
  Future<HostSourceRuntimePageResult> executePopular({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) => Future.error(PlatformException(code: 'ERR'));

  @override
  Future<HostSourceRuntimePageResult> executeSearch({
    required String sourceId,
    required String query,
    int page = 1,
    int pageSize = 20,
  }) => Future.error(PlatformException(code: 'ERR'));
}
