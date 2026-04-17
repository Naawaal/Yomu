import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../domain/entities/repository_config.dart';

/// Repository-management section for settings.
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

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: InsetsTokens.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    AppStrings.settingsSectionRepositories,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onAddRepository,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.settingsRepositoryAdd),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            if (repositories.isEmpty)
              Text(
                AppStrings.settingsRepositoriesEmpty,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...repositories.map((RepositoryConfig repository) {
                return Padding(
                  key: ValueKey<String>(repository.id),
                  padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _statusIcon(repository.healthStatus),
                      color: _statusColor(colorScheme, repository.healthStatus),
                    ),
                    title: Text(repository.displayName),
                    subtitle: Text(repository.baseUrl),
                    trailing: Wrap(
                      spacing: SpacingTokens.xs,
                      children: <Widget>[
                        IconButton(
                          tooltip: AppStrings.settingsRepositoryValidate,
                          onPressed: () => onValidateRepository(repository.id),
                          icon: const Icon(Icons.verified_rounded),
                        ),
                        IconButton(
                          tooltip: AppStrings.settingsRepositoryRemove,
                          onPressed: () => onRemoveRepository(repository.id),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

IconData _statusIcon(RepositoryHealthStatus status) {
  switch (status) {
    case RepositoryHealthStatus.healthy:
      return Icons.check_circle_rounded;
    case RepositoryHealthStatus.unhealthy:
      return Icons.error_rounded;
    case RepositoryHealthStatus.unknown:
      return Icons.help_rounded;
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
