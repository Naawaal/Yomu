import '../../domain/entities/extension_item.dart';
import '../../domain/repositories/extension_repository.dart';
import '../../domain/usecases/load_remote_extensions_usecase.dart';

/// Composition repository that merges native/installed and remote catalog data.
class CompositeExtensionRepository implements ExtensionRepository {
  /// Creates a composite extension repository.
  const CompositeExtensionRepository({
    required ExtensionRepository primaryRepository,
    required LoadRemoteExtensionsUseCase loadRemoteExtensions,
  }) : _primaryRepository = primaryRepository,
       _loadRemoteExtensions = loadRemoteExtensions;

  final ExtensionRepository _primaryRepository;
  final LoadRemoteExtensionsUseCase _loadRemoteExtensions;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async {
    final List<ExtensionItem> installed = await _primaryRepository
        .getAvailableExtensions();

    List<ExtensionItem> remote = const <ExtensionItem>[];
    try {
      remote = await _loadRemoteExtensions();
    } catch (_) {
      if (installed.isEmpty) {
        rethrow;
      }
      remote = const <ExtensionItem>[];
    }

    final Map<String, ExtensionItem> merged = <String, ExtensionItem>{
      for (final ExtensionItem item in remote) item.packageName: item,
    };

    for (final ExtensionItem item in installed) {
      final ExtensionItem? remoteEntry = merged[item.packageName];
      if (remoteEntry == null) {
        merged[item.packageName] = item;
        continue;
      }

      merged[item.packageName] = ExtensionItem(
        name: remoteEntry.name,
        packageName: item.packageName,
        language: remoteEntry.language,
        versionName: remoteEntry.versionName,
        isInstalled: true,
        hasUpdate: item.hasUpdate,
        isNsfw: remoteEntry.isNsfw || item.isNsfw,
        trustStatus: item.trustStatus,
        installArtifact: remoteEntry.installArtifact ?? item.installArtifact,
        iconUrl: remoteEntry.iconUrl ?? item.iconUrl,
      );
    }

    final List<ExtensionItem> values = merged.values.toList(growable: false)
      ..sort(
        (ExtensionItem left, ExtensionItem right) =>
            left.name.toLowerCase().compareTo(right.name.toLowerCase()),
      );

    return values;
  }

  @override
  Future<void> install(String packageName, {String? installArtifact}) {
    return _primaryRepository.install(
      packageName,
      installArtifact: installArtifact,
    );
  }

  @override
  Future<void> trust(String packageName) {
    return _primaryRepository.trust(packageName);
  }
}
