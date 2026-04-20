import 'package:flutter/foundation.dart';

import '../../domain/entities/extension_item.dart';
import '../../domain/repositories/extension_repository.dart';

/// Mock repository used while the Android bridge is not wired yet.
///
/// Singleton pattern ensures trust state persists across provider calls during development.
/// When native bridge becomes available, it will override this mock.
class MockExtensionRepository implements ExtensionRepository {
  /// Private constructor for singleton.
  MockExtensionRepository._();

  /// Shared state persisted across all access to the mock repository.
  static final List<ExtensionItem> _items = <ExtensionItem>[
    const ExtensionItem(
      name: 'MangaDex',
      packageName: 'eu.kanade.tachiyomi.extension.en.mangadex',
      language: 'en',
      versionName: '1.4.9',
      isInstalled: true,
      hasUpdate: true,
      isNsfw: false,
      trustStatus: ExtensionTrustStatus.trusted,
      installArtifact: null,
      iconUrl:
          'https://cdn.jsdelivr.net/gh/tachiyomiorg/tachiyomi-extensions@master/src/en/mangadex/icon.png',
    ),
    const ExtensionItem(
      name: 'NekoScans',
      packageName: 'eu.kanade.tachiyomi.extension.all.nekoscans',
      language: 'all',
      versionName: '1.4.5',
      isInstalled: true,
      hasUpdate: false,
      isNsfw: true,
      trustStatus: ExtensionTrustStatus.untrusted,
      installArtifact: null,
      iconUrl: null,
    ),
  ];

  /// Singleton instance accessed via [instance] getter.
  static final MockExtensionRepository _instance = MockExtensionRepository._();

  /// Returns the singleton instance.
  static MockExtensionRepository get instance => _instance;

  /// Resets items to initial state (for testing purposes only).
  @visibleForTesting
  static void resetForTesting() {
    _items.clear();
    _items.addAll(<ExtensionItem>[
      const ExtensionItem(
        name: 'MangaDex',
        packageName: 'eu.kanade.tachiyomi.extension.en.mangadex',
        language: 'en',
        versionName: '1.4.9',
        isInstalled: true,
        hasUpdate: true,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
        installArtifact: null,
        iconUrl:
            'https://cdn.jsdelivr.net/gh/tachiyomiorg/tachiyomi-extensions@master/src/en/mangadex/icon.png',
      ),
      const ExtensionItem(
        name: 'NekoScans',
        packageName: 'eu.kanade.tachiyomi.extension.all.nekoscans',
        language: 'all',
        versionName: '1.4.5',
        isInstalled: true,
        hasUpdate: false,
        isNsfw: true,
        trustStatus: ExtensionTrustStatus.untrusted,
        installArtifact: null,
        iconUrl: null,
      ),
    ]);
  }

  /// Adds a temporary item for testing.
  @visibleForTesting
  static void addItemForTesting(ExtensionItem item) {
    _items.add(item);
  }

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async {
    return List<ExtensionItem>.unmodifiable(_items);
  }

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {
    final int index = _items.indexWhere((e) => e.packageName == packageName);
    if (index < 0) {
      return;
    }

    final ExtensionItem current = _items[index];
    _items[index] = ExtensionItem(
      name: current.name,
      packageName: current.packageName,
      language: current.language,
      versionName: current.versionName,
      isInstalled: true,
      hasUpdate: current.hasUpdate,
      isNsfw: current.isNsfw,
      trustStatus: current.trustStatus,
      installArtifact: installArtifact ?? current.installArtifact,
      iconUrl: current.iconUrl,
    );
  }

  @override
  Future<void> trust(String packageName) async {
    final int index = _items.indexWhere((e) => e.packageName == packageName);
    if (index < 0) {
      return;
    }
    final ExtensionItem current = _items[index];
    _items[index] = ExtensionItem(
      name: current.name,
      packageName: current.packageName,
      language: current.language,
      versionName: current.versionName,
      isInstalled: current.isInstalled,
      hasUpdate: current.hasUpdate,
      isNsfw: current.isNsfw,
      trustStatus: ExtensionTrustStatus.trusted,
      installArtifact: current.installArtifact,
      iconUrl: current.iconUrl,
    );
  }
}
