import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
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
        final String? feedbackMessage = ref.read(
          settingsOperationFeedbackProvider,
        );
        final String snackbarMessage =
            feedbackMessage ?? AppStrings.settingsOperationCompleted;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snackbarMessage)));
        if (feedbackMessage != null) {
          ref.read(settingsOperationFeedbackProvider.notifier).state = null;
        }
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar.medium(title: Text(AppStrings.settings)),
          SliverPadding(
            padding: InsetsTokens.page,
            sliver: asyncSettings.when(
              loading: () => SliverList.list(
                children: <Widget>[
                  LoadingShimmer(
                    child: Column(
                      children: <Widget>[
                        _SettingsLoadingCard(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SettingsLoadingCard(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SettingsLoadingCard(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              error: (Object error, StackTrace _) => SliverToBoxAdapter(
                child: ErrorState(
                  title: AppStrings.unableToLoadApp,
                  message: error.toString(),
                  retryLabel: AppStrings.retry,
                  onRetry: () {
                    ref.read(settingsControllerProvider.notifier).refresh();
                  },
                ),
              ),
              data: (SettingsSnapshot snapshot) {
                return SliverList.list(
                  children: <Widget>[
                    const _SettingsSectionHeader(
                      title: AppStrings.settingsSectionTheme,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ThemeSettingsSectionWidget(
                      selectedPreference: snapshot.themePreference,
                      onThemeChanged: (AppThemePreference preference) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .setThemePreference(preference);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SettingsSectionHeader(
                      title: AppStrings.settingsSectionBackup,
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.lg),
                    const _SettingsSectionHeader(
                      title: AppStrings.settingsSectionRepositories,
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
                        _confirmRemoveRepositoryDialog(
                          context,
                          ref,
                          repositoryId,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

Future<void> _showAddRepositoryDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  String repositoryName = '';
  String repositoryUrl = '';

  final (String?, String?) input =
      await AppDialog.show<(String?, String?)>(
        context: context,
        title: AppStrings.settingsAddRepositoryTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppTextInput(
              label: AppStrings.settingsRepositoryNameLabel,
              onChanged: (String value) {
                repositoryName = value;
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextInput(
              label: AppStrings.settingsRepositoryUrlLabel,
              keyboardType: TextInputType.url,
              onChanged: (String value) {
                repositoryUrl = value;
              },
            ),
          ],
        ),
        actionsBuilder: (BuildContext dialogContext) => <Widget>[
          AppButton.outlined(
            label: AppStrings.settingsCancel,
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          AppButton(
            label: AppStrings.settingsAdd,
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop((repositoryName.trim(), repositoryUrl.trim()));
            },
          ),
        ],
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

Future<void> _confirmRemoveRepositoryDialog(
  BuildContext context,
  WidgetRef ref,
  String repositoryId,
) async {
  final bool confirmed =
      await AppDialog.show<bool>(
        context: context,
        title: AppStrings.settingsRemoveRepositoryTitle,
        content: const Text(AppStrings.settingsRemoveRepositoryBody),
        actionsBuilder: (BuildContext dialogContext) => <Widget>[
          AppButton.outlined(
            label: AppStrings.settingsCancel,
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
          ),
          AppButton.destructive(
            label: AppStrings.settingsRemove,
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
          ),
        ],
      ) ??
      false;

  if (!confirmed || !context.mounted) {
    return;
  }

  await ref
      .read(settingsControllerProvider.notifier)
      .removeRepository(repositoryId);
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
}

class _SettingsLoadingCard extends StatelessWidget {
  const _SettingsLoadingCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const SizedBox(height: AppSpacing.xxxl),
    );
  }
}
