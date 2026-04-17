import '../entities/settings_snapshot.dart';
import '../repositories/settings_repository.dart';

/// Imports a backup snapshot through the settings repository.
class ImportBackupUseCase {
  /// Creates a use case for importing backups.
  const ImportBackupUseCase(this._repository);

  final SettingsRepository _repository;

  /// Executes the use case.
  Future<BackupSnapshot> call() {
    return _repository.importBackup();
  }
}
