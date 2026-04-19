import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/features/extensions/data/repositories/composite_extension_repository.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/domain/repositories/extension_repository.dart';
import 'package:yomu/features/extensions/domain/repositories/remote_extension_catalog_repository.dart';
import 'package:yomu/features/extensions/domain/usecases/load_remote_extensions_usecase.dart';

class _FakePrimaryRepository implements ExtensionRepository {
  _FakePrimaryRepository({required this.items});

  final List<ExtensionItem> items;
  String? lastTrusted;
  String? lastInstalled;
  String? lastInstallArtifact;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async => items;

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {
    lastInstalled = packageName;
    lastInstallArtifact = installArtifact;
  }

  @override
  Future<void> trust(String packageName) async {
    lastTrusted = packageName;
  }
}

class _FakeRemoteCatalogRepository implements RemoteExtensionCatalogRepository {
  _FakeRemoteCatalogRepository(this.items);

  final List<ExtensionItem> items;

  @override
  Future<List<ExtensionItem>> getRemoteExtensions() async => items;
}

class _ThrowingRemoteCatalogRepository
    implements RemoteExtensionCatalogRepository {
  const _ThrowingRemoteCatalogRepository();

  @override
  Future<List<ExtensionItem>> getRemoteExtensions() {
    throw Exception('network down');
  }
}

void main() {
  group('CompositeExtensionRepository', () {
    test(
      'merges installed and remote items with trust from installed',
      () async {
        final _FakePrimaryRepository primary = _FakePrimaryRepository(
          items: const <ExtensionItem>[
            ExtensionItem(
              name: 'MangaDex Installed',
              packageName: 'eu.kanade.tachiyomi.extension.all.mangadex',
              language: 'all',
              versionName: '1.1.0',
              hasUpdate: true,
              isNsfw: false,
              trustStatus: ExtensionTrustStatus.trusted,
            ),
          ],
        );
        final _FakeRemoteCatalogRepository remote =
            _FakeRemoteCatalogRepository(const <ExtensionItem>[
              ExtensionItem(
                name: 'MangaDex Remote',
                packageName: 'eu.kanade.tachiyomi.extension.all.mangadex',
                language: 'all',
                versionName: '2.0.0',
                hasUpdate: false,
                isNsfw: false,
                trustStatus: ExtensionTrustStatus.untrusted,
                installArtifact: 'https://repo.example/mangadex.apk',
              ),
              ExtensionItem(
                name: 'NekoScans',
                packageName: 'eu.kanade.tachiyomi.extension.en.nekoscans',
                language: 'en',
                versionName: '1.0.0',
                hasUpdate: false,
                isNsfw: true,
                trustStatus: ExtensionTrustStatus.untrusted,
                installArtifact: 'https://repo.example/nekoscans.apk',
              ),
            ]);

        final CompositeExtensionRepository repository =
            CompositeExtensionRepository(
              primaryRepository: primary,
              loadRemoteExtensions: LoadRemoteExtensionsUseCase(remote),
            );

        final List<ExtensionItem> items = await repository
            .getAvailableExtensions();

        expect(items, hasLength(2));
        final ExtensionItem mangadex = items.firstWhere(
          (ExtensionItem item) =>
              item.packageName == 'eu.kanade.tachiyomi.extension.all.mangadex',
        );
        expect(mangadex.trustStatus, ExtensionTrustStatus.trusted);
        expect(mangadex.hasUpdate, isTrue);
        expect(mangadex.installArtifact, 'https://repo.example/mangadex.apk');
      },
    );

    test(
      'prefers remote presentation fields and preserves installed safety fields',
      () async {
        final _FakePrimaryRepository primary = _FakePrimaryRepository(
          items: const <ExtensionItem>[
            ExtensionItem(
              name: 'Installed Name',
              packageName: 'pkg.shared',
              language: 'en',
              versionName: '1.0.0',
              hasUpdate: true,
              isNsfw: false,
              trustStatus: ExtensionTrustStatus.trusted,
              installArtifact: 'https://installed.example/old.apk',
              iconUrl: 'https://installed.example/icon.png',
            ),
          ],
        );
        final _FakeRemoteCatalogRepository remote =
            _FakeRemoteCatalogRepository(const <ExtensionItem>[
              ExtensionItem(
                name: 'Remote Name',
                packageName: 'pkg.shared',
                language: 'ja',
                versionName: '2.0.0',
                hasUpdate: false,
                isNsfw: true,
                trustStatus: ExtensionTrustStatus.untrusted,
                installArtifact: 'https://repo.example/new.apk',
                iconUrl: 'https://repo.example/icon.png',
              ),
            ]);

        final CompositeExtensionRepository repository =
            CompositeExtensionRepository(
              primaryRepository: primary,
              loadRemoteExtensions: LoadRemoteExtensionsUseCase(remote),
            );

        final List<ExtensionItem> items = await repository
            .getAvailableExtensions();
        final ExtensionItem merged = items.single;

        expect(merged.name, 'Remote Name');
        expect(merged.language, 'ja');
        expect(merged.versionName, '2.0.0');
        expect(merged.trustStatus, ExtensionTrustStatus.trusted);
        expect(merged.hasUpdate, isTrue);
        expect(merged.isNsfw, isTrue);
        expect(merged.installArtifact, 'https://repo.example/new.apk');
        expect(merged.iconUrl, 'https://repo.example/icon.png');
      },
    );

    test('keeps installed item when remote load fails', () async {
      final _FakePrimaryRepository primary = _FakePrimaryRepository(
        items: const <ExtensionItem>[
          ExtensionItem(
            name: 'Installed Only',
            packageName: 'pkg.installed.only',
            language: 'en',
            versionName: '1.0.0',
            hasUpdate: false,
            isNsfw: false,
            trustStatus: ExtensionTrustStatus.trusted,
          ),
        ],
      );

      final CompositeExtensionRepository repository =
          CompositeExtensionRepository(
            primaryRepository: primary,
            loadRemoteExtensions: LoadRemoteExtensionsUseCase(
              const _ThrowingRemoteCatalogRepository(),
            ),
          );

      final List<ExtensionItem> items = await repository
          .getAvailableExtensions();

      expect(items, hasLength(1));
      expect(items.single.packageName, 'pkg.installed.only');
      expect(items.single.trustStatus, ExtensionTrustStatus.trusted);
    });

    test('delegates trust/install actions to primary repository', () async {
      final _FakePrimaryRepository primary = _FakePrimaryRepository(
        items: const <ExtensionItem>[],
      );
      final _FakeRemoteCatalogRepository remote = _FakeRemoteCatalogRepository(
        const <ExtensionItem>[],
      );
      final CompositeExtensionRepository repository =
          CompositeExtensionRepository(
            primaryRepository: primary,
            loadRemoteExtensions: LoadRemoteExtensionsUseCase(remote),
          );

      await repository.trust('pkg.test');
      await repository.install(
        'pkg.test',
        installArtifact: 'https://repo.example/pkg.test.apk',
      );

      expect(primary.lastTrusted, 'pkg.test');
      expect(primary.lastInstalled, 'pkg.test');
      expect(primary.lastInstallArtifact, 'https://repo.example/pkg.test.apk');
    });
  });
}
