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
///
/// ## Page Structure & Hierarchy
/// - AppBar: SliverAppBar.medium (standard header with back button)
/// - Content: Three-card section layout:
///   1. Theme Settings (appearance/display preferences)
///   2. Backup Settings (data export/import)
///   3. Repository Settings (extension source management)
///
/// ## Spacing Rhythm
/// - Page margins: AppSpacing.md (horizontal) + AppSpacing.lg (top/bottom via InsetsTokens)
/// - Section gaps: AppSpacing.lg (between cards)
/// - Card internal padding: AppSpacing.md (all sides)
/// - Card radius: AppRadius.md (standard rounded corner)
/// - Bottom safe area: AppSpacing.xl
///
/// ## Sliver Structure Contract
/// - SliverAppBar.medium provides dismissible header with scroll sync
/// - SliverPadding applies page-level margins (InsetsTokens.page)
/// - SliverList renders each section as a card container
/// - Each card is self-contained with header title + widget content
/// - Section header uses titleSmall typography with onSurfaceVariant color
/// - Full-page loading state during initial data fetch (transitions to per-section states in TODO-SET-002)
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.settingsOperationFailedTryAgain)),
        );
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
          /// Standard medium app bar with settings title
          const SliverAppBar.medium(title: Text(AppStrings.settings)),

          /// Page-level padding container
          SliverPadding(
            padding: InsetsTokens.page,
            sliver: asyncSettings.when(
              /// Loading: full-page shimmer skeleton matching section card layout
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

              /// Error: full-page error state with retry action
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

              /// Data: three-card section layout
              /// Card hierarchy: [Theme] → [Backup] → [Repositories]
              data: (SettingsSnapshot snapshot) {
                return SliverList.list(
                  children: <Widget>[
                    /// ━━━ SECTION 1: THEME SETTINGS ━━━
                    /// Structure: title + card container with widget
                    /// Overlay: per-section loading/error state
                    _SectionWithOperationState(
                      title: AppStrings.settingsSectionTheme,
                      operation: SettingsSectionOperation.themeChange,
                      child: ThemeSettingsSectionWidget(
                        selectedPreference: snapshot.themePreference,
                        onThemeChanged: (AppThemePreference preference) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .setThemePreference(preference);
                        },
                      ),
                    ),

                    /// Section gap: AppSpacing.lg (consistent inter-section spacing)
                    const SizedBox(height: AppSpacing.lg),

                    /// ━━━ SECTION 2: BACKUP SETTINGS ━━━
                    /// Structure: title + card container with widget
                    /// Overlay: per-section loading/error state (monitors backupExport + backupImport)
                    /// Note: Backup section has two operations (export/import).
                    /// Currently monitored separately, but visually merged in one section.
                    _SectionWithOperationState(
                      title: AppStrings.settingsSectionBackup,
                      operation: SettingsSectionOperation.backupExport,
                      child: BackupSettingsSectionWidget(
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
                    ),

                    /// Section gap: AppSpacing.lg (consistent inter-section spacing)
                    const SizedBox(height: AppSpacing.lg),

                    /// ━━━ SECTION 3: REPOSITORY SETTINGS ━━━
                    /// Structure: title + card container with widget
                    /// Overlay: per-section loading/error state (monitors repositoryAdd)
                    /// Note: Repository section has multiple operations (add/remove/validate).
                    /// Currently monitored by add operation as primary; validate/remove have own states.
                    _SectionWithOperationState(
                      title: AppStrings.settingsSectionRepositories,
                      operation: SettingsSectionOperation.repositoryAdd,
                      child: RepositorySettingsSectionWidget(
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
                    ),
                  ],
                );
              },
            ),
          ),

          /// Bottom safe area spacing
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

/// ┌─────────────────────────────────────────────────────────────────┐
/// │ SECTION WITH OPERATION STATE OVERLAY                           │
/// │ Wraps section card with per-section loading/error indicators   │
/// │ (TODO-SET-011: Integrates sectionOperationStateProvider)       │
/// └─────────────────────────────────────────────────────────────────┘
///
/// Displays:
/// - Shimmer overlay when operation is loading
/// - Error banner when operation fails
/// - Normal section card otherwise
///
/// Architecture:
/// - Watches sectionOperationStateProvider
/// - Filters events for the specific operation type this section handles
/// - Full snapshot state independent (always current)
/// - Per-section state for UI feedback only
class _SectionWithOperationState extends ConsumerWidget {
  const _SectionWithOperationState({
    required this.title,
    required this.operation,
    required this.child,
  });

  /// Section title
  final String title;

  /// Operation type this section monitors
  final SettingsSectionOperation operation;

  /// Section card content
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SectionOperationState operationState = ref.watch(
      sectionOperationStateProvider,
    );

    // Check if this section's operation is currently loading or errored
    final bool isThisSectionLoading =
        operationState.operation == operation && operationState.isLoading;
    final bool isThisSectionErrored =
        operationState.operation == operation && operationState.hasError;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: <Widget>[
        /// Base section card (always visible, content may be obscured by overlay)
        _SettingsSectionCard(title: title, child: child),

        /// Loading overlay: shimmer effect over the section
        if (isThisSectionLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: colorScheme.surface.withValues(alpha: 0.85),
              ),
              child: LoadingShimmer(
                child: Container(color: colorScheme.surfaceContainerHighest),
              ),
            ),
          ),

        /// Error overlay: error message banner at bottom of section
        if (isThisSectionErrored)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.md),
                  bottomRight: Radius.circular(AppRadius.md),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppStrings.settingsOperationFailedTryAgain,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// ┌─────────────────────────────────────────────────────────────────┐
/// │ SECTION CARD CONTAINER                                          │
/// │ Wraps each settings section (Theme, Backup, Repositories)      │
/// │ with consistent card styling, internal padding, and title      │
/// └─────────────────────────────────────────────────────────────────┘
///
/// Card Contract:
/// - Outer container: Material.surface with outlineVariant border
/// - Border radius: AppRadius.md (12dp)
/// - Internal padding: AppSpacing.md (16dp all sides)
/// - Section title: titleSmall + onSurfaceVariant color
/// - Title-to-content gap: AppSpacing.sm (12dp)
/// - Shadow: none (M3 uses tonal elevation via surface color)
///
/// Accessibility (TODO-SET-006):
/// - Semantic container for screen readers
/// - Title acts as section heading
/// - Content child rendered within semantic context
class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.title, required this.child});

  /// Section header text (e.g., "Theme", "Backup", "Repositories")
  final String title;

  /// Content widget rendered below the title
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: title,
      child: Card(
        /// M3 card styling: no elevation, bordered, tonal surface
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          /// Consistent internal padding for all section cards
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// Section title: titleSmall weight + onSurfaceVariant color
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                semanticsLabel: title,
              ),

              /// Title-to-content gap
              const SizedBox(height: AppSpacing.sm),

              /// Section content widget
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// ┌─────────────────────────────────────────────────────────────────┐
/// │ LOADING SKELETON CARD                                           │
/// │ Placeholder card during full-page loading state                │
/// │ (Transitions to per-card shimmer in TODO-SET-002)              │
/// └─────────────────────────────────────────────────────────────────┘
///
/// Skeleton matching section card dimensions for placeholder fidelity
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
