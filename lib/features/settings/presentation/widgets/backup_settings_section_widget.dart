import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';
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
    return AppCard(
      child: Column(
        children: <Widget>[
          AppListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Ionicons.cloud_upload_outline),
            title: const Text(AppStrings.settingsBackupExport),
            subtitle: Text(
              '${AppStrings.settingsBackupLastExport}: ${_formatTimestamp(backup.lastExportedAt)}',
            ),
            trailing: const Icon(Ionicons.chevron_forward_outline),
            onTap: onExportBackup,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Ionicons.cloud_download_outline),
            title: const Text(AppStrings.settingsBackupImport),
            subtitle: Text(
              '${AppStrings.settingsBackupLastImport}: ${_formatTimestamp(backup.lastImportedAt)}',
            ),
            trailing: const Icon(Ionicons.chevron_forward_outline),
            onTap: onImportBackup,
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
