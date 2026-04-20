import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/entities/repository_config.dart';

/// Repository-management section for settings.
///
/// ## Card Ownership (TODO-SET-001, TODO-SET-005)
///
/// This widget renders **content only** (no card, no title).
/// The parent [SettingsScreen] wraps it in [_SettingsSectionCard] which provides:
/// - Card styling (bordered, tonal surface, AppRadius.md)
/// - Section title (AppStrings.settingsSectionRepositories)
/// - Internal padding (AppSpacing.md)
///
/// This widget's responsibility:
/// - Render repository list items (or empty state)
/// - Display health status with icons/colors
/// - Render action buttons (validate/remove per repository)
/// - Render "Add Repository" action button
///
/// Accessibility (TODO-SET-006):
/// - Semantic list container for screen readers
/// - Each repository item includes status in semantic label
/// - Action buttons have tooltips for keyboard/a11y users
/// - Empty state announced with semantic label
///
/// Layout: Column of list items or empty state, followed by add button.
class RepositorySettingsSectionWidget extends StatelessWidget {
  /// Creates a repository settings section widget.
  const RepositorySettingsSectionWidget({
    super.key,
    required this.repositories,
    required this.onAddRepository,
    required this.onValidateRepository,
    required this.onRemoveRepository,
  });

  /// Configured repositories.
  final List<RepositoryConfig> repositories;

  /// Invoked when adding repository is requested.
  final VoidCallback onAddRepository;

  /// Invoked when validating a repository is requested.
  final ValueChanged<String> onValidateRepository;

  /// Invoked when removing a repository is requested.
  final ValueChanged<String> onRemoveRepository;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: AppStrings.settingsRepositorySectionSemantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (repositories.isEmpty)
            Semantics(
              label: AppStrings.settingsRepositoryEmptySemantics,
              enabled: true,
              child: Text(
                AppStrings.settingsRepositoriesEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...repositories.indexed.expand((
              (int, RepositoryConfig) entry,
            ) sync* {
              final int index = entry.$1;
              final RepositoryConfig repository = entry.$2;
              final String statusLabel = _statusLabel(repository.healthStatus);

              yield Semantics(
                label:
                    '${repository.displayName}, ${statusLabel.toLowerCase()}',
                enabled: true,
                child: AppListTile(
                  key: ValueKey<String>(repository.id),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _statusIcon(repository.healthStatus),
                    color: _statusColor(colorScheme, repository.healthStatus),
                  ),
                  title: Text(repository.displayName),
                  subtitle: Text(statusLabel),
                  trailing: _RepositoryActions(
                    repositoryId: repository.id,
                    onValidateRepository: onValidateRepository,
                    onRemoveRepository: onRemoveRepository,
                  ),
                ),
              );

              if (index != repositories.length - 1) {
                yield const SizedBox(height: AppSpacing.xs);
              }
            }),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            button: true,
            enabled: true,
            onTap: onAddRepository,
            label: AppStrings.settingsRepositoryAddSemantics,
            child: AppButton.outlined(
              label: AppStrings.settingsRepositoryAdd,
              leadingIcon: const Icon(Ionicons.add_outline),
              onPressed: onAddRepository,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _statusIcon(RepositoryHealthStatus status) {
  switch (status) {
    case RepositoryHealthStatus.healthy:
      return Ionicons.checkmark_circle_outline;
    case RepositoryHealthStatus.unhealthy:
      return Ionicons.alert_circle_outline;
    case RepositoryHealthStatus.unknown:
      return Ionicons.help_circle_outline;
  }
}

Color _statusColor(ColorScheme colorScheme, RepositoryHealthStatus status) {
  switch (status) {
    case RepositoryHealthStatus.healthy:
      return colorScheme.primary;
    case RepositoryHealthStatus.unhealthy:
      return colorScheme.error;
    case RepositoryHealthStatus.unknown:
      return colorScheme.onSurfaceVariant;
  }
}

String _statusLabel(RepositoryHealthStatus status) {
  switch (status) {
    case RepositoryHealthStatus.healthy:
      return AppStrings.settingsRepositoryHealthyLabel;
    case RepositoryHealthStatus.unhealthy:
      return AppStrings.settingsRepositoryUnhealthyLabel;
    case RepositoryHealthStatus.unknown:
      return AppStrings.settingsRepositoryUnknownLabel;
  }
}

class _RepositoryActions extends StatelessWidget {
  const _RepositoryActions({
    required this.repositoryId,
    required this.onValidateRepository,
    required this.onRemoveRepository,
  });

  final String repositoryId;
  final ValueChanged<String> onValidateRepository;
  final ValueChanged<String> onRemoveRepository;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: AppStrings.settingsRepositoryValidate,
          onPressed: () => onValidateRepository(repositoryId),
          icon: const Icon(Ionicons.shield_checkmark_outline),
        ),
        IconButton(
          tooltip: AppStrings.settingsRepositoryRemove,
          onPressed: () => onRemoveRepository(repositoryId),
          icon: const Icon(Ionicons.trash_outline),
        ),
      ],
    );
  }
}
