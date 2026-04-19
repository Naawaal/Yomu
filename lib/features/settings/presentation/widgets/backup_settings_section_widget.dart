import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/entities/settings_snapshot.dart';

/// Backup controls section for settings.
///
/// ## Card Ownership (TODO-SET-001, TODO-SET-004)
///
/// This widget renders **content only** (no card, no title).
/// The parent [SettingsScreen] wraps it in [_SettingsSectionCard] which provides:
/// - Card styling (bordered, tonal surface, AppRadius.md)
/// - Section title (AppStrings.settingsSectionBackup)
/// - Internal padding (AppSpacing.md)
///
/// This widget's responsibility:
/// - Render export/import action list items
/// - Display last export/import timestamps
/// - Invoke callbacks on tap
///
/// Accessibility (TODO-SET-006):
/// - Semantic container for list context
/// - Each list tile has semantic tap action
/// - Timestamps included in semantic label for a11y context
///
/// Layout: Column of two tappable list items (export + import) with metadata.
class BackupSettingsSectionWidget extends StatelessWidget {
  /// Creates a backup settings section widget.
  const BackupSettingsSectionWidget({
    super.key,
    required this.backup,
    required this.onExportBackup,
    required this.onImportBackup,
  });

  /// Backup metadata snapshot.
  final BackupSnapshot backup;

  /// Invoked when export is requested.
  final VoidCallback onExportBackup;

  /// Invoked when import is requested.
  final VoidCallback onImportBackup;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Backup actions: export and import',
      child: Column(
        children: <Widget>[
          Semantics(
            label:
                'Export backup, last export: ${_formatTimestamp(backup.lastExportedAt)}',
            enabled: true,
            child: AppListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Ionicons.cloud_upload_outline),
              title: const Text(AppStrings.settingsBackupExport),
              subtitle: Text(
                '${AppStrings.settingsBackupLastExport}: ${_formatTimestamp(backup.lastExportedAt)}',
              ),
              trailing: const Icon(Ionicons.chevron_forward_outline),
              onTap: onExportBackup,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label:
                'Import backup, last import: ${_formatTimestamp(backup.lastImportedAt)}',
            enabled: true,
            child: AppListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Ionicons.cloud_download_outline),
              title: const Text(AppStrings.settingsBackupImport),
              subtitle: Text(
                '${AppStrings.settingsBackupLastImport}: ${_formatTimestamp(backup.lastImportedAt)}',
              ),
              trailing: const Icon(Ionicons.chevron_forward_outline),
              onTap: onImportBackup,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(DateTime? value) {
  if (value == null) {
    return AppStrings.settingsNotAvailable;
  }
  return value.toIso8601String();
}
