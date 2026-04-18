import '../../domain/entities/repository_config.dart';
import '../../../extensions/data/datasources/remote_extension_index_datasource.dart';
import 'settings_local_datasource.dart';

/// Contract for CRUD and validation of managed repositories.
abstract class RepositoryManagementDataSource {
  /// Returns all configured repositories.
  Future<List<RepositoryConfig>> getRepositories();

  /// Adds a repository and returns the updated collection.
  Future<List<RepositoryConfig>> addRepository(RepositoryConfig repository);

  /// Updates a repository and returns the updated collection.
  Future<List<RepositoryConfig>> updateRepository(RepositoryConfig repository);

  /// Removes a repository and returns the updated collection.
  Future<List<RepositoryConfig>> removeRepository(String repositoryId);

  /// Validates repository health and returns the updated repository.
  Future<RepositoryConfig> validateRepository(String repositoryId);
}

/// Shared-preferences backed repository-management datasource.
class LocalRepositoryManagementDataSource
    implements RepositoryManagementDataSource {
  /// Creates a repository-management datasource.
  const LocalRepositoryManagementDataSource({
    required SettingsLocalDataSource localDataSource,
    required RemoteExtensionIndexDataSource remoteIndexDataSource,
  }) : _localDataSource = localDataSource,
       _remoteIndexDataSource = remoteIndexDataSource;

  final SettingsLocalDataSource _localDataSource;
  final RemoteExtensionIndexDataSource _remoteIndexDataSource;

  @override
  Future<List<RepositoryConfig>> addRepository(
    RepositoryConfig repository,
  ) async {
    final List<RepositoryConfig> current = await _localDataSource
        .getRepositories();

    final bool exists = current.any(
      (RepositoryConfig item) => item.id == repository.id,
    );
    if (exists) {
      throw StateError('Repository with id ${repository.id} already exists.');
    }

    final List<RepositoryConfig> next = <RepositoryConfig>[
      ...current,
      repository,
    ];
    await _localDataSource.saveRepositories(next);
    return next;
  }

  @override
  Future<List<RepositoryConfig>> getRepositories() {
    return _localDataSource.getRepositories();
  }

  @override
  Future<List<RepositoryConfig>> removeRepository(String repositoryId) async {
    final List<RepositoryConfig> current = await _localDataSource
        .getRepositories();
    final List<RepositoryConfig> next = current
        .where((RepositoryConfig item) => item.id != repositoryId)
        .toList(growable: false);
    await _localDataSource.saveRepositories(next);
    return next;
  }

  @override
  Future<List<RepositoryConfig>> updateRepository(
    RepositoryConfig repository,
  ) async {
    final List<RepositoryConfig> current = await _localDataSource
        .getRepositories();

    final int index = current.indexWhere(
      (RepositoryConfig item) => item.id == repository.id,
    );
    if (index < 0) {
      throw StateError('Repository with id ${repository.id} was not found.');
    }

    final List<RepositoryConfig> next = List<RepositoryConfig>.from(current)
      ..[index] = repository;

    await _localDataSource.saveRepositories(next);
    return List<RepositoryConfig>.unmodifiable(next);
  }

  @override
  Future<RepositoryConfig> validateRepository(String repositoryId) async {
    final List<RepositoryConfig> current = await _localDataSource
        .getRepositories();

    final int index = current.indexWhere(
      (RepositoryConfig item) => item.id == repositoryId,
    );
    if (index < 0) {
      throw StateError('Repository with id $repositoryId was not found.');
    }

    final RepositoryConfig repository = current[index];

    // Attempt to fetch and parse the repository index.
    RepositoryHealthStatus healthStatus = RepositoryHealthStatus.unhealthy;
    try {
      final Uri? uri = Uri.tryParse(repository.baseUrl);
      if (uri != null &&
          uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https')) {
        // Try to fetch and parse the index
        await _remoteIndexDataSource.fetchRepositoryIndex(uri);
        healthStatus = RepositoryHealthStatus.healthy;
      }
    } catch (_) {
      // If fetch or parse fails, mark as unhealthy
      healthStatus = RepositoryHealthStatus.unhealthy;
    }

    final RepositoryConfig validated = RepositoryConfig(
      id: repository.id,
      displayName: repository.displayName,
      baseUrl: repository.baseUrl,
      isEnabled: repository.isEnabled,
      healthStatus: healthStatus,
      lastValidatedAt: DateTime.now(),
    );

    final List<RepositoryConfig> next = List<RepositoryConfig>.from(current)
      ..[index] = validated;

    await _localDataSource.saveRepositories(next);
    return validated;
  }
}
