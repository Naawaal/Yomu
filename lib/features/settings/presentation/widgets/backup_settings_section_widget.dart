import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../domain/entities/settings_snapshot.dart';

/// Backup controls section for settings.
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: InsetsTokens.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppStrings.settingsSectionBackup,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              '${AppStrings.settingsBackupLastExport}: ${_formatTimestamp(backup.lastExportedAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              '${AppStrings.settingsBackupLastImport}: ${_formatTimestamp(backup.lastImportedAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: SpacingTokens.md),
            Wrap(
              spacing: SpacingTokens.sm,
              runSpacing: SpacingTokens.sm,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onExportBackup,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text(AppStrings.settingsBackupExport),
                ),
                OutlinedButton.icon(
                  onPressed: onImportBackup,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text(AppStrings.settingsBackupImport),
                ),
              ],
            ),
          ],
        ),
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
