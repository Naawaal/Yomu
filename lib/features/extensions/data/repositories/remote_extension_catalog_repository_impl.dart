import '../../../settings/domain/repositories/settings_repository.dart';
import '../../domain/entities/extension_item.dart';
import '../../domain/repositories/remote_extension_catalog_repository.dart';
import '../datasources/remote_extension_index_datasource.dart';
import '../models/remote_extension_index_model.dart';

/// Resolves extension entries from user-configured remote repositories.
class RemoteExtensionCatalogRepositoryImpl
    implements RemoteExtensionCatalogRepository {
  /// Creates a repository implementation backed by settings + HTTP datasource.
  const RemoteExtensionCatalogRepositoryImpl({
    required SettingsRepository settingsRepository,
    required RemoteExtensionIndexDataSource dataSource,
  }) : _settingsRepository = settingsRepository,
       _dataSource = dataSource;

  final SettingsRepository _settingsRepository;
  final RemoteExtensionIndexDataSource _dataSource;

  @override
  Future<List<ExtensionItem>> getRemoteExtensions() async {
    final List<ExtensionItem> resolved = <ExtensionItem>[];
    final List repositories = await _settingsRepository.getRepositories();

    for (final repository in repositories) {
      if (!repository.isEnabled) {
        continue;
      }

      final Uri? repositoryUri = Uri.tryParse(repository.baseUrl);
      if (repositoryUri == null) {
        continue;
      }

      try {
        final RemoteExtensionIndexModel index = await _dataSource
            .fetchRepositoryIndex(repositoryUri);
        resolved.addAll(
          index.extensions.map(
            (RemoteExtensionEntryModel entry) => entry.toExtensionItem(
              trustStatus: ExtensionTrustStatus.untrusted,
              hasUpdate: false,
            ),
          ),
        );
      } on RemoteExtensionIndexException {
        // Skip invalid/unreachable repositories; composition layer can still
        // surface installed extensions and any successful remote entries.
      }
    }

    final Map<String, ExtensionItem> deduped = <String, ExtensionItem>{};
    for (final ExtensionItem item in resolved) {
      deduped.putIfAbsent(item.packageName, () => item);
    }

    return deduped.values.toList(growable: false);
  }
}
