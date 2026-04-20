import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/domain/repositories/extension_repository.dart';
import 'package:yomu/features/extensions/domain/usecases/get_installed_sources_usecase.dart';

class _FakeExtensionRepository implements ExtensionRepository {
  const _FakeExtensionRepository(this.items);

  final List<ExtensionItem> items;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async => items;

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {}

  @override
  Future<void> trust(String packageName) async {}
}

void main() {
  group('GetInstalledSourcesUseCase', () {
    test('returns only installed sources in repository order', () async {
      const ExtensionItem installedFirst = ExtensionItem(
        name: 'Installed First',
        packageName: 'pkg.installed.first',
        language: 'en',
        versionName: '1.0.0',
        isInstalled: true,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
      );
      const ExtensionItem uninstalled = ExtensionItem(
        name: 'Uninstalled',
        packageName: 'pkg.uninstalled',
        language: 'en',
        versionName: '1.0.0',
        isInstalled: false,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.untrusted,
      );
      const ExtensionItem installedSecond = ExtensionItem(
        name: 'Installed Second',
        packageName: 'pkg.installed.second',
        language: 'ja',
        versionName: '2.0.0',
        isInstalled: true,
        hasUpdate: true,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
      );

      final GetInstalledSourcesUseCase useCase = GetInstalledSourcesUseCase(
        const _FakeExtensionRepository(<ExtensionItem>[
          installedFirst,
          uninstalled,
          installedSecond,
        ]),
      );

      final List<ExtensionItem> installed = await useCase();

      expect(installed, hasLength(2));
      expect(
        installed,
        containsAllInOrder(<ExtensionItem>[installedFirst, installedSecond]),
      );
      expect(installed.every((ExtensionItem item) => item.isInstalled), isTrue);
    });

    test('returns empty list when no sources are installed', () async {
      final GetInstalledSourcesUseCase useCase = GetInstalledSourcesUseCase(
        const _FakeExtensionRepository(<ExtensionItem>[
          ExtensionItem(
            name: 'Remote Only',
            packageName: 'pkg.remote.only',
            language: 'en',
            versionName: '1.0.0',
            isInstalled: false,
            hasUpdate: false,
            isNsfw: false,
            trustStatus: ExtensionTrustStatus.untrusted,
          ),
        ]),
      );

      final List<ExtensionItem> installed = await useCase();

      expect(installed, isEmpty);
    });
  });
}
