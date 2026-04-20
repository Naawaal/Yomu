import '../../../settings/domain/repositories/settings_repository.dart';
import '../../domain/entities/extension_item.dart';
import '../../domain/repositories/remote_extension_catalog_repository.dart';
import '../datasources/remote_extension_index_datasource.dart';
import '../models/remote_extension_index_model.dart';

/// Actionable failure detail for a configured remote extension repository.
class RemoteRepositoryFailureDetail {
  /// Creates a repository failure detail.
  const RemoteRepositoryFailureDetail({
    required this.repositoryId,
    required this.displayName,
    required this.baseUrl,
    required this.reason,
  });

  /// Stable repository id from settings.
  final String repositoryId;

  /// Human-friendly repository display name.
  final String displayName;

  /// Configured repository URL.
  final String baseUrl;

  /// Actionable failure reason.
  final String reason;

  @override
  String toString() {
    return '$displayName ($baseUrl): $reason';
  }
}

/// Thrown when all enabled remote repositories fail and no entries can be shown.
class RemoteExtensionCatalogAggregateException implements Exception {
  /// Creates an aggregated catalog exception.
  const RemoteExtensionCatalogAggregateException(this.failures);

  /// Failure details grouped per repository.
  final List<RemoteRepositoryFailureDetail> failures;

  @override
  String toString() {
    final String joined = failures
        .map((RemoteRepositoryFailureDetail failure) => '- $failure')
        .join('\n');
    return 'Unable to load remote extension catalog.\n$joined';
  }
}

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
    final List<RemoteRepositoryFailureDetail> failures =
        <RemoteRepositoryFailureDetail>[];
    final List repositories = await _settingsRepository.getRepositories();

    for (final repository in repositories) {
      if (!repository.isEnabled) {
        continue;
      }

      final Uri? repositoryUri = Uri.tryParse(repository.baseUrl);
      if (repositoryUri == null) {
        failures.add(
          RemoteRepositoryFailureDetail(
            repositoryId: repository.id,
            displayName: repository.displayName,
            baseUrl: repository.baseUrl,
            reason: 'Invalid repository URL.',
          ),
        );
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
              repositoryUri: repositoryUri,
            ),
          ),
        );
      } on RemoteExtensionIndexException catch (error) {
        failures.add(
          RemoteRepositoryFailureDetail(
            repositoryId: repository.id,
            displayName: repository.displayName,
            baseUrl: repository.baseUrl,
            reason: error.message,
          ),
        );
      } on Exception catch (error) {
        failures.add(
          RemoteRepositoryFailureDetail(
            repositoryId: repository.id,
            displayName: repository.displayName,
            baseUrl: repository.baseUrl,
            reason: error.toString(),
          ),
        );
      }
    }

    final Map<String, ExtensionItem> deduped = <String, ExtensionItem>{};
    for (final ExtensionItem item in resolved) {
      deduped.putIfAbsent(item.packageName, () => item);
    }

    final List<ExtensionItem> values = deduped.values.toList(growable: false);
    if (values.isEmpty && failures.isNotEmpty) {
      throw RemoteExtensionCatalogAggregateException(
        failures.toList(growable: false),
      );
    }

    return values;
  }
}
