import '../../domain/entities/repository_config.dart';
import '../../domain/entities/settings_snapshot.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/backup_datasource.dart';
import '../datasources/repository_management_datasource.dart';
import '../datasources/settings_local_datasource.dart';

/// Settings repository implementation composed from dedicated datasources.
class SettingsRepositoryImpl implements SettingsRepository {
  /// Creates a settings repository implementation.
  const SettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
    required BackupDataSource backupDataSource,
    required RepositoryManagementDataSource repositoryManagementDataSource,
  }) : _localDataSource = localDataSource,
       _backupDataSource = backupDataSource,
       _repositoryManagementDataSource = repositoryManagementDataSource;

  final SettingsLocalDataSource _localDataSource;
  final BackupDataSource _backupDataSource;
  final RepositoryManagementDataSource _repositoryManagementDataSource;

  @override
  Future<List<RepositoryConfig>> addRepository(RepositoryConfig repository) {
    return _repositoryManagementDataSource.addRepository(repository);
  }

  @override
  Future<BackupSnapshot> exportBackup() {
    return _backupDataSource.exportBackup();
  }

  @override
  Future<BackupSnapshot> importBackup() {
    return _backupDataSource.importBackup();
  }

  @override
  Future<List<RepositoryConfig>> getRepositories() {
    return _repositoryManagementDataSource.getRepositories();
  }

  @override
  Future<SettingsSnapshot> getSettingsSnapshot() async {
    final AppThemePreference themePreference = await _localDataSource
        .getThemePreference();
    final BackupSnapshot backup = await _localDataSource.getBackupSnapshot();
    final List<RepositoryConfig> repositories =
        await _repositoryManagementDataSource.getRepositories();

    return SettingsSnapshot(
      themePreference: themePreference,
      backup: backup,
      repositories: repositories,
    );
  }

  @override
  Future<List<RepositoryConfig>> removeRepository(String repositoryId) {
    return _repositoryManagementDataSource.removeRepository(repositoryId);
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) {
    return _localDataSource.setThemePreference(preference);
  }

  @override
  Future<List<RepositoryConfig>> updateRepository(RepositoryConfig repository) {
    return _repositoryManagementDataSource.updateRepository(repository);
  }

  @override
  Future<RepositoryConfig> validateRepository(String repositoryId) {
    return _repositoryManagementDataSource.validateRepository(repositoryId);
  }
}
