import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/tokens.dart';
import '../../../settings/domain/entities/repository_config.dart';
import '../../../settings/domain/entities/settings_snapshot.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/widgets/backup_settings_section_widget.dart';
import '../../../settings/presentation/widgets/repository_settings_section_widget.dart';
import '../../../settings/presentation/widgets/theme_settings_section_widget.dart';

/// Settings root screen shown in the main application shell.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SettingsSnapshot> asyncSettings = ref.watch(
      settingsControllerProvider,
    );

    ref.listen<AsyncValue<SettingsSnapshot>>(settingsControllerProvider, (
      AsyncValue<SettingsSnapshot>? previous,
      AsyncValue<SettingsSnapshot> next,
    ) {
      if (previous == null || previous.isLoading) {
        return;
      }

      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
        return;
      }

      if (next.hasValue && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.settingsOperationCompleted)),
        );
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar.large(title: Text(AppStrings.settings)),
          SliverPadding(
            padding: InsetsTokens.page,
            sliver: asyncSettings.when(
              loading: () => SliverList.list(
                children: const <Widget>[
                  _SettingsLoadingCard(),
                  SizedBox(height: SpacingTokens.sm),
                  _SettingsLoadingCard(),
                  SizedBox(height: SpacingTokens.sm),
                  _SettingsLoadingCard(),
                ],
              ),
              error: (Object error, StackTrace _) => SliverToBoxAdapter(
                child: _SettingsErrorCard(
                  message: error.toString(),
                  onRetry: () {
                    ref.read(settingsControllerProvider.notifier).refresh();
                  },
                ),
              ),
              data: (SettingsSnapshot snapshot) {
                return SliverList.list(
                  children: <Widget>[
                    ThemeSettingsSectionWidget(
                      selectedPreference: snapshot.themePreference,
                      onThemeChanged: (AppThemePreference preference) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setThemePreference(preference);
                      },
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    BackupSettingsSectionWidget(
                      backup: snapshot.backup,
                      onExportBackup: () {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .exportBackup();
                      },
                      onImportBackup: () {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .importBackup();
                      },
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    RepositorySettingsSectionWidget(
                      repositories: snapshot.repositories,
                      onAddRepository: () {
                        _showAddRepositoryDialog(context, ref);
                      },
                      onValidateRepository: (String repositoryId) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .validateRepository(repositoryId);
                      },
                      onRemoveRepository: (String repositoryId) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .removeRepository(repositoryId);
                      },
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    const _SettingsSectionHeader(
                      title: AppStrings.settingsSectionContent,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    const _ExtensionsManagerTile(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddRepositoryDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final (String?, String?) input =
      await showDialog<(String?, String?)>(
        context: context,
        builder: (BuildContext context) {
          return const _AddRepositoryDialog();
        },
      ) ??
      (null, null);

  if (!context.mounted) {
    return;
  }

  final String name = input.$1 ?? '';
  final String url = input.$2 ?? '';
  if (name.isEmpty || url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.settingsRepositoryInputInvalid)),
    );
    return;
  }

  final String repositoryId = name.toLowerCase().replaceAll(' ', '-');
  await ref
      .read(settingsControllerProvider.notifier)
      .addRepository(
        RepositoryConfig(
          id: repositoryId,
          displayName: name,
          baseUrl: url,
          isEnabled: true,
          healthStatus: RepositoryHealthStatus.unknown,
          lastValidatedAt: null,
        ),
      );
}

/// Dialog widget for adding a new repository.
class _AddRepositoryDialog extends StatefulWidget {
  /// Creates the add repository dialog.
  const _AddRepositoryDialog();

  @override
  State<_AddRepositoryDialog> createState() => _AddRepositoryDialogState();
}

class _AddRepositoryDialogState extends State<_AddRepositoryDialog> {
  late final TextEditingController nameController;
  late final TextEditingController urlController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    urlController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.settingsAddRepositoryTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: AppStrings.settingsRepositoryNameLabel,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: AppStrings.settingsRepositoryUrlLabel,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(AppStrings.settingsCancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop((nameController.text.trim(), urlController.text.trim()));
          },
          child: const Text(AppStrings.settingsAdd),
        ),
      ],
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _SettingsLoadingCard extends StatelessWidget {
  const _SettingsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const SizedBox(height: SpacingTokens.xxxl),
    );
  }
}

class _SettingsErrorCard extends StatelessWidget {
  const _SettingsErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: InsetsTokens.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: SpacingTokens.sm),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtensionsManagerTile extends StatelessWidget {
  const _ExtensionsManagerTile();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: ListTile(
        contentPadding: InsetsTokens.card,
        leading: Icon(Icons.extension_rounded, color: colorScheme.primary),
        title: Text(
          AppStrings.extensionsTitle,
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          AppStrings.settingsExtensionsSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          ExtensionsStoreRoute.go(context);
        },
      ),
    );
  }
}
