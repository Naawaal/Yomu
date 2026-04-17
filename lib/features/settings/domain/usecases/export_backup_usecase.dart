import '../entities/settings_snapshot.dart';
import '../repositories/settings_repository.dart';

/// Exports a backup snapshot through the settings repository.
class ExportBackupUseCase {
  /// Creates a use case for exporting backups.
  const ExportBackupUseCase(this._repository);

  final SettingsRepository _repository;

  /// Executes the use case.
  Future<BackupSnapshot> call() {
    return _repository.exportBackup();
  }
}
