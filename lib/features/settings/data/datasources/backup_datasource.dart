import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/repository_config.dart';
import '../../domain/entities/settings_snapshot.dart';
import 'settings_local_datasource.dart';

const String _latestBackupPayloadKey = 'settings.backup.latest_payload';
const int _backupSchemaVersion = 1;

/// Contract for backup export/import operations.
abstract class BackupDataSource {
  /// Exports a backup payload and returns updated metadata.
  Future<BackupSnapshot> exportBackup();

  /// Imports the most recent backup payload and returns updated metadata.
  Future<BackupSnapshot> importBackup();
}

/// Shared preferences backup implementation for baseline backup behavior.
class SharedPreferencesBackupDataSource implements BackupDataSource {
  /// Creates a backup datasource.
  const SharedPreferencesBackupDataSource({
    required SettingsLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<BackupSnapshot> exportBackup() async {
    final AppThemePreference themePreference = await _localDataSource
        .getThemePreference();
    final List<RepositoryConfig> repositories = await _localDataSource
        .getRepositories();
    final BackupSnapshot previous = await _localDataSource.getBackupSnapshot();

    final DateTime exportedAt = DateTime.now();
    final Map<String, Object?> payload = <String, Object?>{
      'version': _backupSchemaVersion,
      'themePreference': themePreference.name,
      'repositories': repositories
          .map(
            (RepositoryConfig repository) => <String, Object?>{
              'id': repository.id,
              'displayName': repository.displayName,
              'baseUrl': repository.baseUrl,
              'isEnabled': repository.isEnabled,
              'healthStatus': repository.healthStatus.name,
              'lastValidatedAt': repository.lastValidatedAt?.toIso8601String(),
            },
          )
          .toList(growable: false),
      'exportedAt': exportedAt.toIso8601String(),
    };

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_latestBackupPayloadKey, jsonEncode(payload));

    final BackupSnapshot next = BackupSnapshot(
      version: _backupSchemaVersion,
      lastExportedAt: exportedAt,
      lastImportedAt: previous.lastImportedAt,
    );
    await _localDataSource.saveBackupSnapshot(next);
    return next;
  }

  @override
  Future<BackupSnapshot> importBackup() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? rawPayload = preferences.getString(_latestBackupPayloadKey);
    if (rawPayload == null || rawPayload.isEmpty) {
      throw StateError('No backup payload available for import.');
    }

    final Object? decoded = jsonDecode(rawPayload);
    final Map<String, Object?> payload = decoded is Map<String, Object?>
        ? decoded
        : <String, Object?>{};

    final AppThemePreference themePreference = _themeFromRaw(
      payload['themePreference'] as String?,
    );
    final List<RepositoryConfig> repositories = _repositoriesFromRaw(
      payload['repositories'],
    );

    await _localDataSource.setThemePreference(themePreference);
    await _localDataSource.saveRepositories(repositories);

    final BackupSnapshot previous = await _localDataSource.getBackupSnapshot();
    final DateTime importedAt = DateTime.now();
    final BackupSnapshot next = BackupSnapshot(
      version: payload['version'] as int? ?? previous.version,
      lastExportedAt: previous.lastExportedAt,
      lastImportedAt: importedAt,
    );
    await _localDataSource.saveBackupSnapshot(next);
    return next;
  }
}

AppThemePreference _themeFromRaw(String? value) {
  switch (value) {
    case 'light':
      return AppThemePreference.light;
    case 'dark':
      return AppThemePreference.dark;
    case 'system':
    default:
      return AppThemePreference.system;
  }
}

List<RepositoryConfig> _repositoriesFromRaw(Object? value) {
  final List<Object?> list = value is List<Object?> ? value : const <Object?>[];

  return list
      .map((Object? entry) {
        final Map<String, Object?> map = entry is Map<String, Object?>
            ? entry
            : <String, Object?>{};
        return RepositoryConfig(
          id: map['id'] as String? ?? '',
          displayName: map['displayName'] as String? ?? '',
          baseUrl: map['baseUrl'] as String? ?? '',
          isEnabled: map['isEnabled'] as bool? ?? true,
          healthStatus: _healthFromRaw(map['healthStatus'] as String?),
          lastValidatedAt: DateTime.tryParse(
            map['lastValidatedAt'] as String? ?? '',
          ),
        );
      })
      .toList(growable: false);
}

RepositoryHealthStatus _healthFromRaw(String? value) {
  switch (value) {
    case 'healthy':
      return RepositoryHealthStatus.healthy;
    case 'unhealthy':
      return RepositoryHealthStatus.unhealthy;
    case 'unknown':
    default:
      return RepositoryHealthStatus.unknown;
  }
}
