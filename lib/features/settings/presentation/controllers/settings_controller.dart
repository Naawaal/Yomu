import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../extensions/data/datasources/remote_extension_index_datasource.dart';
import '../../../extensions/data/models/remote_extension_index_model.dart';
import '../../data/datasources/backup_datasource.dart';
import '../../data/datasources/repository_management_datasource.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/repository_config.dart';
import '../../domain/entities/settings_snapshot.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/export_backup_usecase.dart';
import '../../domain/usecases/import_backup_usecase.dart';
import '../../domain/usecases/manage_repository_usecase.dart';
import '../../domain/usecases/update_theme_mode_usecase.dart';

part 'settings_controller.g.dart';

/// Provides HTTP client for repository index validation.
final Provider<RemoteExtensionIndexHttpClient>
repositoryValidationHttpClientProvider =
    Provider<RemoteExtensionIndexHttpClient>(
      (Ref ref) => const DartIoRemoteExtensionIndexHttpClient(),
    );

/// Provides datasource for repository index validation.
final Provider<RemoteExtensionIndexDataSource>
repositoryValidationDataSourceProvider =
    Provider<RemoteExtensionIndexDataSource>((Ref ref) {
      return RemoteExtensionIndexHttpDataSource(
        httpClient: ref.watch(repositoryValidationHttpClientProvider),
      );
    });

/// Transient feedback message surfaced for settings operations.
final StateProvider<String?> settingsOperationFeedbackProvider =
    StateProvider<String?>((Ref ref) => null);

/// Enum tracking which settings section is currently performing an operation.
/// Used for section-scoped loading/error states (prevents full-page blocks).
///
/// Section-scoped state model (TODO-SET-002):
/// - Each section can independently show loading/error during its operation
/// - Full-page snapshot loading on initial load (separate from operations)
/// - Operations include: theme change, backup export/import, repository add/remove/validate
enum SettingsSectionOperation {
  /// No section is performing an operation; all sections are idle/success.
  none,

  /// Theme section is processing a theme preference change.
  themeChange,

  /// Backup section is exporting settings backup.
  backupExport,

  /// Backup section is importing settings backup.
  backupImport,

  /// Repository section is adding a new repository.
  repositoryAdd,

  /// Repository section is removing an existing repository.
  repositoryRemove,

  /// Repository section is validating a repository URL/index.
  repositoryValidate,
}

/// Tracks the active section operation and any error state.
///
/// Usage:
/// - When a section operation starts: set operation type
/// - On success: clear operation (set to none)
/// - On error: keep operation type and store error object
/// - Screen reads this to show per-section loading/error indicators
@immutable
class SectionOperationState {
  /// Creates an operation state snapshot.
  const SectionOperationState({required this.operation, this.error});

  /// Currently executing operation (none = idle).
  final SettingsSectionOperation operation;

  /// Error object if operation failed; null if successful or loading.
  final Object? error;

  /// True if a section operation is actively executing.
  bool get isLoading =>
      operation != SettingsSectionOperation.none && error == null;

  /// True if the most recent operation encountered an error.
  bool get hasError => error != null;

  /// Factory for idle state (no operation in progress).
  factory SectionOperationState.idle() =>
      const SectionOperationState(operation: SettingsSectionOperation.none);

  /// Factory for error state.
  factory SectionOperationState.error(
    SettingsSectionOperation operation,
    Object error,
  ) => SectionOperationState(operation: operation, error: error);
}

/// Provides per-section operation state for presentation layer.
///
/// This enables section-scoped loading/error indicators instead of full-page blocks.
/// Each operation (theme change, backup export, repository add, etc.) updates this state
/// independently from the full-page SettingsSnapshot load state.
///
/// Architecture note:
/// - Domain/data layers unchanged (still return full SettingsSnapshot)
/// - Presentation layer tracks operation-level state separately
/// - Allows atomic UI feedback per section without architectural refactor
final StateProvider<SectionOperationState> sectionOperationStateProvider =
    StateProvider<SectionOperationState>((Ref ref) {
      return SectionOperationState.idle();
    });

/// Provides the local settings datasource implementation.
@riverpod
SettingsLocalDataSource settingsLocalDataSource(Ref ref) {
  return const SharedPreferencesSettingsLocalDataSource();
}

/// Provides backup datasource implementation.
@riverpod
BackupDataSource backupDataSource(Ref ref) {
  return SharedPreferencesBackupDataSource(
    localDataSource: ref.watch(settingsLocalDataSourceProvider),
  );
}

/// Provides repository-management datasource implementation.
@riverpod
RepositoryManagementDataSource repositoryManagementDataSource(Ref ref) {
  return LocalRepositoryManagementDataSource(
    localDataSource: ref.watch(settingsLocalDataSourceProvider),
    remoteIndexDataSource: ref.watch(repositoryValidationDataSourceProvider),
  );
}

/// Provides settings repository implementation.
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepositoryImpl(
    localDataSource: ref.watch(settingsLocalDataSourceProvider),
    backupDataSource: ref.watch(backupDataSourceProvider),
    repositoryManagementDataSource: ref.watch(
      repositoryManagementDataSourceProvider,
    ),
  );
}

/// Provides use case for updating theme mode.
@riverpod
UpdateThemeModeUseCase updateThemeModeUseCase(Ref ref) {
  return UpdateThemeModeUseCase(ref.watch(settingsRepositoryProvider));
}

/// Provides use case for exporting backup.
@riverpod
ExportBackupUseCase exportBackupUseCase(Ref ref) {
  return ExportBackupUseCase(ref.watch(settingsRepositoryProvider));
}

/// Provides use case for importing backup.
@riverpod
ImportBackupUseCase importBackupUseCase(Ref ref) {
  return ImportBackupUseCase(ref.watch(settingsRepositoryProvider));
}

/// Provides use case for repository management operations.
@riverpod
ManageRepositoryUseCase manageRepositoryUseCase(Ref ref) {
  return ManageRepositoryUseCase(ref.watch(settingsRepositoryProvider));
}

/// Provides app-level [ThemeMode] derived from persisted settings.
@riverpod
ThemeMode appThemeMode(Ref ref) {
  final AsyncValue<SettingsSnapshot> asyncSettings = ref.watch(
    settingsControllerProvider,
  );

  return asyncSettings.maybeWhen(
    data: (SettingsSnapshot snapshot) {
      return _toThemeMode(snapshot.themePreference);
    },
    orElse: () => ThemeMode.system,
  );
}

/// Async controller for settings state and mutation actions.
///
/// ## State Architecture (Section-Scoped Behavior Model — TODO-SET-002)
///
/// ### Primary State: `settingsControllerProvider`
/// - Type: `AsyncValue<SettingsSnapshot>`
/// - Lifecycle: Loads once on app start; reloads on refresh() or after operations
/// - Contains: Full settings state (theme, backup metadata, repositories)
/// - Loading: Full-page shimmer during initial load
/// - Error: Full-page error state with retry
///
/// ### Secondary State: `sectionOperationStateProvider`
/// - Type: `SectionOperationState`
/// - Lifecycle: Tracks active operation; cleared after success/error
/// - Contains: Operation type (themeChange, backupExport, repositoryAdd, etc.) + error
/// - Usage: Show per-section loading/error overlays without blocking other sections
///
/// ### Integration Pattern (Future TODOs)
/// - When user performs operation → update `sectionOperationStateProvider` to loading
/// - Controller method still reloads full snapshot (as now)
/// - Screen watches BOTH providers:
///   - Main state for data display
///   - Section operation state for per-section loading/error indicators
/// - After operation completes → section operation state auto-clears
///
/// ### Benefits
/// - Theme section shows loading only during theme change (backup/repository unaffected)
/// - Backup section shows loading during export/import (theme/repository unaffected)
/// - Repository operations don't block other sections
/// - Full snapshot is always current (no stale data issues)
/// - No changes needed to domain/data layers
///
/// ### Current Implementation Status
/// - ✅ State model defined (SettingsSectionOperation, SectionOperationState)
/// - ✅ Provider created (sectionOperationStateProvider)
/// - ⏳ Controller methods updated (in progress — TODO-SET-002)
/// - ⏳ Screen integration (TODO-SET-011)
/// - ⏳ Per-section shimmer loading (TODO-SET-002)
@riverpod
class SettingsController extends _$SettingsController {
  @override
  Future<SettingsSnapshot> build() {
    return _loadSnapshot();
  }

  /// Reloads settings from persistence.
  Future<void> refresh() async {
    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(_loadSnapshot);
  }

  /// Updates the selected app theme preference.
  Future<void> setThemePreference(AppThemePreference preference) async {
    final UpdateThemeModeUseCase useCase = ref.read(
      updateThemeModeUseCaseProvider,
    );

    // Mark theme section as loading
    ref.read(sectionOperationStateProvider.notifier).state =
        SectionOperationState(operation: SettingsSectionOperation.themeChange);

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase(UpdateThemeModeParams(preference: preference));
      return _loadSnapshot();
    });

    // Clear operation state on completion (success or error)
    if (!state.hasError) {
      ref.read(sectionOperationStateProvider.notifier).state =
          SectionOperationState.idle();
    } else {
      ref
          .read(sectionOperationStateProvider.notifier)
          .state = SectionOperationState.error(
        SettingsSectionOperation.themeChange,
        state.error ?? Exception('Unknown error'),
      );
    }
  }

  /// Exports settings backup and updates state metadata.
  Future<void> exportBackup() async {
    final ExportBackupUseCase useCase = ref.read(exportBackupUseCaseProvider);

    // Mark backup section as loading (export operation)
    ref.read(sectionOperationStateProvider.notifier).state =
        SectionOperationState(operation: SettingsSectionOperation.backupExport);

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase();
      return _loadSnapshot();
    });

    // Clear operation state on completion (success or error)
    if (!state.hasError) {
      ref.read(sectionOperationStateProvider.notifier).state =
          SectionOperationState.idle();
    } else {
      ref
          .read(sectionOperationStateProvider.notifier)
          .state = SectionOperationState.error(
        SettingsSectionOperation.backupExport,
        state.error ?? Exception('Unknown error'),
      );
    }
  }

  /// Imports settings backup and updates state metadata.
  Future<void> importBackup() async {
    final ImportBackupUseCase useCase = ref.read(importBackupUseCaseProvider);

    // Mark backup section as loading (import operation)
    ref.read(sectionOperationStateProvider.notifier).state =
        SectionOperationState(operation: SettingsSectionOperation.backupImport);

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase();
      return _loadSnapshot();
    });

    // Clear operation state on completion (success or error)
    if (!state.hasError) {
      ref.read(sectionOperationStateProvider.notifier).state =
          SectionOperationState.idle();
    } else {
      ref
          .read(sectionOperationStateProvider.notifier)
          .state = SectionOperationState.error(
        SettingsSectionOperation.backupImport,
        state.error ?? Exception('Unknown error'),
      );
    }
  }

  /// Adds a repository entry and updates settings state.
  Future<void> addRepository(RepositoryConfig repository) async {
    final ManageRepositoryUseCase useCase = ref.read(
      manageRepositoryUseCaseProvider,
    );

    // Mark repository section as loading (add operation)
    ref
        .read(sectionOperationStateProvider.notifier)
        .state = SectionOperationState(
      operation: SettingsSectionOperation.repositoryAdd,
    );

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase(AddRepositoryCommand(repository));
      return _loadSnapshot();
    });

    // Clear operation state on completion (success or error)
    if (!state.hasError) {
      ref.read(sectionOperationStateProvider.notifier).state =
          SectionOperationState.idle();
    } else {
      ref
          .read(sectionOperationStateProvider.notifier)
          .state = SectionOperationState.error(
        SettingsSectionOperation.repositoryAdd,
        state.error ?? Exception('Unknown error'),
      );
    }
  }

  /// Updates a repository entry and updates settings state.
  Future<void> updateRepository(RepositoryConfig repository) async {
    final ManageRepositoryUseCase useCase = ref.read(
      manageRepositoryUseCaseProvider,
    );

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase(UpdateRepositoryCommand(repository));
      return _loadSnapshot();
    });
  }

  /// Removes a repository entry and updates settings state.
  Future<void> removeRepository(String repositoryId) async {
    final ManageRepositoryUseCase useCase = ref.read(
      manageRepositoryUseCaseProvider,
    );

    // Mark repository section as loading (remove operation)
    ref
        .read(sectionOperationStateProvider.notifier)
        .state = SectionOperationState(
      operation: SettingsSectionOperation.repositoryRemove,
    );

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase(RemoveRepositoryCommand(repositoryId));
      return _loadSnapshot();
    });

    // Clear operation state on completion (success or error)
    if (!state.hasError) {
      ref.read(sectionOperationStateProvider.notifier).state =
          SectionOperationState.idle();
    } else {
      ref
          .read(sectionOperationStateProvider.notifier)
          .state = SectionOperationState.error(
        SettingsSectionOperation.repositoryRemove,
        state.error ?? Exception('Unknown error'),
      );
    }
  }

  /// Validates a repository entry and updates settings state.
  Future<void> validateRepository(String repositoryId) async {
    final ManageRepositoryUseCase useCase = ref.read(
      manageRepositoryUseCaseProvider,
    );
    final SettingsRepository repository = ref.read(settingsRepositoryProvider);
    final RemoteExtensionIndexDataSource validator = ref.read(
      repositoryValidationDataSourceProvider,
    );

    // Mark repository section as loading (validate operation)
    ref
        .read(sectionOperationStateProvider.notifier)
        .state = SectionOperationState(
      operation: SettingsSectionOperation.repositoryValidate,
    );

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      final List<RepositoryConfig> repositories = await repository
          .getRepositories();
      final RepositoryConfig source = repositories.firstWhere(
        (RepositoryConfig item) => item.id == repositoryId,
        orElse: () {
          throw StateError('Repository with id $repositoryId was not found.');
        },
      );

      RepositoryHealthStatus healthStatus = RepositoryHealthStatus.unhealthy;
      String feedbackMessage =
          AppStrings.settingsRepositoryValidationInvalidUrl;
      final Uri? uri = Uri.tryParse(source.baseUrl);
      final bool hasSupportedScheme =
          uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
      if (hasSupportedScheme) {
        try {
          await validator.fetchRepositoryIndex(uri);
          healthStatus = RepositoryHealthStatus.healthy;
          feedbackMessage = AppStrings.settingsRepositoryValidationSuccess;
        } on RemoteExtensionIndexInvalidFormatException {
          healthStatus = RepositoryHealthStatus.unhealthy;
          feedbackMessage = AppStrings.settingsRepositoryValidationInvalidIndex;
        } on RemoteExtensionIndexUnreachableException {
          healthStatus = RepositoryHealthStatus.unhealthy;
          feedbackMessage = AppStrings.settingsRepositoryValidationUnreachable;
        } on RemoteExtensionIndexException {
          healthStatus = RepositoryHealthStatus.unhealthy;
          feedbackMessage = AppStrings.settingsRepositoryValidationUnreachable;
        }
      }

      final RepositoryConfig validated = RepositoryConfig(
        id: source.id,
        displayName: source.displayName,
        baseUrl: source.baseUrl,
        isEnabled: source.isEnabled,
        healthStatus: healthStatus,
        lastValidatedAt: DateTime.now(),
      );

      await useCase(UpdateRepositoryCommand(validated));
      ref.read(settingsOperationFeedbackProvider.notifier).state =
          feedbackMessage;
      return _loadSnapshot();
    });

    // Clear operation state on completion (success or error)
    if (!state.hasError) {
      ref.read(sectionOperationStateProvider.notifier).state =
          SectionOperationState.idle();
    } else {
      ref
          .read(sectionOperationStateProvider.notifier)
          .state = SectionOperationState.error(
        SettingsSectionOperation.repositoryValidate,
        state.error ?? Exception('Unknown error'),
      );
    }
  }

  Future<SettingsSnapshot> _loadSnapshot() {
    return ref.read(settingsRepositoryProvider).getSettingsSnapshot();
  }
}

ThemeMode _toThemeMode(AppThemePreference preference) {
  switch (preference) {
    case AppThemePreference.light:
      return ThemeMode.light;
    case AppThemePreference.dark:
      return ThemeMode.dark;
    case AppThemePreference.system:
      return ThemeMode.system;
  }
}
