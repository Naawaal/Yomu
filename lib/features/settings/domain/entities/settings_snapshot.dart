import 'repository_config.dart';

/// User-selectable application theme preference.
enum AppThemePreference {
  /// Follow system preference.
  system,

  /// Force light mode.
  light,

  /// Force dark mode.
  dark,
}

/// Backup state metadata for settings and app content.
class BackupSnapshot {
  /// Creates backup metadata snapshot.
  const BackupSnapshot({
    required this.version,
    this.lastExportedAt,
    this.lastImportedAt,
  });

  /// Schema version used by backup payloads.
  final int version;

  /// Timestamp of the most recent successful export.
  final DateTime? lastExportedAt;

  /// Timestamp of the most recent successful import.
  final DateTime? lastImportedAt;
}

/// Aggregate settings state consumed by presentation.
class SettingsSnapshot {
  /// Creates a settings snapshot.
  const SettingsSnapshot({
    required this.themePreference,
    required this.backup,
    required this.repositories,
  });

  /// Selected app theme behavior.
  final AppThemePreference themePreference;

  /// Backup metadata.
  final BackupSnapshot backup;

  /// Managed repository list.
  final List<RepositoryConfig> repositories;
}
