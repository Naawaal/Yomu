import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/repository_config.dart';
import '../../domain/entities/settings_snapshot.dart';

const String _themePreferenceKey = 'settings.theme_preference';
const String _repositoriesKey = 'settings.repositories';
const String _backupVersionKey = 'settings.backup.version';
const String _backupLastExportedAtKey = 'settings.backup.last_exported_at';
const String _backupLastImportedAtKey = 'settings.backup.last_imported_at';

/// Contract for reading and writing locally persisted settings fields.
abstract class SettingsLocalDataSource {
  /// Reads the persisted theme preference.
  Future<AppThemePreference> getThemePreference();

  /// Persists the theme preference.
  Future<void> setThemePreference(AppThemePreference preference);

  /// Reads the persisted repository list.
  Future<List<RepositoryConfig>> getRepositories();

  /// Persists the repository list.
  Future<void> saveRepositories(List<RepositoryConfig> repositories);

  /// Reads persisted backup metadata.
  Future<BackupSnapshot> getBackupSnapshot();

  /// Persists backup metadata.
  Future<void> saveBackupSnapshot(BackupSnapshot backup);
}

/// Shared preferences implementation of [SettingsLocalDataSource].
class SharedPreferencesSettingsLocalDataSource
    implements SettingsLocalDataSource {
  /// Creates a settings local datasource backed by shared preferences.
  const SharedPreferencesSettingsLocalDataSource();

  @override
  Future<BackupSnapshot> getBackupSnapshot() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final int version = preferences.getInt(_backupVersionKey) ?? 1;
    final DateTime? lastExportedAt = _readDateTime(
      preferences,
      _backupLastExportedAtKey,
    );
    final DateTime? lastImportedAt = _readDateTime(
      preferences,
      _backupLastImportedAtKey,
    );

    return BackupSnapshot(
      version: version,
      lastExportedAt: lastExportedAt,
      lastImportedAt: lastImportedAt,
    );
  }

  @override
  Future<List<RepositoryConfig>> getRepositories() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> encodedRepositories =
        preferences.getStringList(_repositoriesKey) ?? const <String>[];

    return encodedRepositories
        .map((String value) => _repositoryFromJson(value))
        .toList(growable: false);
  }

  @override
  Future<AppThemePreference> getThemePreference() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String rawPreference =
        preferences.getString(_themePreferenceKey) ?? 'system';
    return _themePreferenceFromRaw(rawPreference);
  }

  @override
  Future<void> saveBackupSnapshot(BackupSnapshot backup) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_backupVersionKey, backup.version);

    final String? exportedAt = backup.lastExportedAt?.toIso8601String();
    if (exportedAt == null) {
      await preferences.remove(_backupLastExportedAtKey);
    } else {
      await preferences.setString(_backupLastExportedAtKey, exportedAt);
    }

    final String? importedAt = backup.lastImportedAt?.toIso8601String();
    if (importedAt == null) {
      await preferences.remove(_backupLastImportedAtKey);
    } else {
      await preferences.setString(_backupLastImportedAtKey, importedAt);
    }
  }

  @override
  Future<void> saveRepositories(List<RepositoryConfig> repositories) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> encoded = repositories
        .map((RepositoryConfig item) => _repositoryToJson(item))
        .toList(growable: false);
    await preferences.setStringList(_repositoriesKey, encoded);
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, preference.name);
  }
}

AppThemePreference _themePreferenceFromRaw(String rawPreference) {
  switch (rawPreference) {
    case 'light':
      return AppThemePreference.light;
    case 'dark':
      return AppThemePreference.dark;
    case 'system':
    default:
      return AppThemePreference.system;
  }
}

DateTime? _readDateTime(SharedPreferences preferences, String key) {
  final String? value = preferences.getString(key);
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String _repositoryToJson(RepositoryConfig repository) {
  return jsonEncode(<String, Object?>{
    'id': repository.id,
    'displayName': repository.displayName,
    'baseUrl': repository.baseUrl,
    'isEnabled': repository.isEnabled,
    'healthStatus': repository.healthStatus.name,
    'lastValidatedAt': repository.lastValidatedAt?.toIso8601String(),
  });
}

RepositoryConfig _repositoryFromJson(String value) {
  final Object? decoded = jsonDecode(value);
  final Map<String, Object?> map = decoded is Map<String, Object?>
      ? decoded
      : <String, Object?>{};

  return RepositoryConfig(
    id: map['id'] as String? ?? '',
    displayName: map['displayName'] as String? ?? '',
    baseUrl: map['baseUrl'] as String? ?? '',
    isEnabled: map['isEnabled'] as bool? ?? true,
    healthStatus: _healthStatusFromRaw(map['healthStatus'] as String?),
    lastValidatedAt: DateTime.tryParse(map['lastValidatedAt'] as String? ?? ''),
  );
}

RepositoryHealthStatus _healthStatusFromRaw(String? rawValue) {
  switch (rawValue) {
    case 'healthy':
      return RepositoryHealthStatus.healthy;
    case 'unhealthy':
      return RepositoryHealthStatus.unhealthy;
    case 'unknown':
    default:
      return RepositoryHealthStatus.unknown;
  }
}
