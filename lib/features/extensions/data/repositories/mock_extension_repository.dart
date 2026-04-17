import '../../domain/entities/extension_item.dart';
import '../../domain/repositories/extension_repository.dart';

/// Mock repository used while the Android bridge is not wired yet.
class MockExtensionRepository implements ExtensionRepository {
  final List<ExtensionItem> _items = <ExtensionItem>[
    const ExtensionItem(
      name: 'MangaDex',
      packageName: 'eu.kanade.tachiyomi.extension.en.mangadex',
      language: 'en',
      versionName: '1.4.9',
      hasUpdate: true,
      isNsfw: false,
      trustStatus: ExtensionTrustStatus.trusted,
      installArtifact: null,
    ),
    const ExtensionItem(
      name: 'NekoScans',
      packageName: 'eu.kanade.tachiyomi.extension.all.nekoscans',
      language: 'all',
      versionName: '1.4.5',
      hasUpdate: false,
      isNsfw: true,
      trustStatus: ExtensionTrustStatus.untrusted,
      installArtifact: null,
    ),
  ];

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async {
    return List<ExtensionItem>.unmodifiable(_items);
  }

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {
    return;
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
      hasUpdate: current.hasUpdate,
      isNsfw: current.isNsfw,
      trustStatus: ExtensionTrustStatus.trusted,
      installArtifact: current.installArtifact,
    );
  }
}
