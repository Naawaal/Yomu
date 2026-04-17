import '../entities/repository_config.dart';
import '../entities/settings_snapshot.dart';

/// Domain contract for settings persistence and operations.
abstract class SettingsRepository {
  /// Reads the latest persisted settings snapshot.
  Future<SettingsSnapshot> getSettingsSnapshot();

  /// Persists a selected theme preference.
  Future<void> setThemePreference(AppThemePreference preference);

  /// Exports settings/content backup and returns resulting metadata.
  Future<BackupSnapshot> exportBackup();

  /// Imports settings/content backup and returns resulting metadata.
  Future<BackupSnapshot> importBackup();

  /// Returns all configured repositories.
  Future<List<RepositoryConfig>> getRepositories();

  /// Adds a new repository configuration.
  Future<List<RepositoryConfig>> addRepository(RepositoryConfig repository);

  /// Updates an existing repository configuration.
  Future<List<RepositoryConfig>> updateRepository(RepositoryConfig repository);

  /// Removes repository by identifier.
  Future<List<RepositoryConfig>> removeRepository(String repositoryId);

  /// Validates repository connectivity and returns updated configuration.
  Future<RepositoryConfig> validateRepository(String repositoryId);
}
