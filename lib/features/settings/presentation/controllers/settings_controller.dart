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

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase(UpdateThemeModeParams(preference: preference));
      return _loadSnapshot();
    });
  }

  /// Exports settings backup and updates state metadata.
  Future<void> exportBackup() async {
    final ExportBackupUseCase useCase = ref.read(exportBackupUseCaseProvider);

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase();
      return _loadSnapshot();
    });
  }

  /// Imports settings backup and updates state metadata.
  Future<void> importBackup() async {
    final ImportBackupUseCase useCase = ref.read(importBackupUseCaseProvider);

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase();
      return _loadSnapshot();
    });
  }

  /// Adds a repository entry and updates settings state.
  Future<void> addRepository(RepositoryConfig repository) async {
    final ManageRepositoryUseCase useCase = ref.read(
      manageRepositoryUseCaseProvider,
    );

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase(AddRepositoryCommand(repository));
      return _loadSnapshot();
    });
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

    state = const AsyncLoading<SettingsSnapshot>();
    state = await AsyncValue.guard(() async {
      await useCase(RemoveRepositoryCommand(repositoryId));
      return _loadSnapshot();
    });
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
