import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/features/extensions/data/datasources/remote_extension_index_datasource.dart';
import 'package:yomu/features/extensions/data/models/remote_extension_index_model.dart';
import 'package:yomu/features/settings/domain/entities/repository_config.dart';
import 'package:yomu/features/settings/domain/entities/settings_snapshot.dart';
import 'package:yomu/features/settings/domain/repositories/settings_repository.dart';
import 'package:yomu/features/settings/presentation/controllers/settings_controller.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._repositories);

  final List<RepositoryConfig> _repositories;
  AppThemePreference _themePreference = AppThemePreference.system;

  @override
  Future<List<RepositoryConfig>> addRepository(
    RepositoryConfig repository,
  ) async {
    _repositories.add(repository);
    return List<RepositoryConfig>.unmodifiable(_repositories);
  }

  @override
  Future<BackupSnapshot> exportBackup() async {
    return const BackupSnapshot(version: 1);
  }

  @override
  Future<List<RepositoryConfig>> getRepositories() async {
    return List<RepositoryConfig>.unmodifiable(_repositories);
  }

  @override
  Future<SettingsSnapshot> getSettingsSnapshot() async {
    return SettingsSnapshot(
      themePreference: _themePreference,
      backup: const BackupSnapshot(version: 1),
      repositories: List<RepositoryConfig>.unmodifiable(_repositories),
    );
  }

  @override
  Future<BackupSnapshot> importBackup() async {
    return const BackupSnapshot(version: 1);
  }

  @override
  Future<List<RepositoryConfig>> removeRepository(String repositoryId) async {
    _repositories.removeWhere(
      (RepositoryConfig item) => item.id == repositoryId,
    );
    return List<RepositoryConfig>.unmodifiable(_repositories);
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) async {
    _themePreference = preference;
  }

  @override
  Future<List<RepositoryConfig>> updateRepository(
    RepositoryConfig repository,
  ) async {
    final int index = _repositories.indexWhere(
      (RepositoryConfig item) => item.id == repository.id,
    );
    if (index >= 0) {
      _repositories[index] = repository;
    }
    return List<RepositoryConfig>.unmodifiable(_repositories);
  }

  @override
  Future<RepositoryConfig> validateRepository(String repositoryId) async {
    final RepositoryConfig repository = _repositories.firstWhere(
      (RepositoryConfig item) => item.id == repositoryId,
    );
    return repository;
  }
}

class _SuccessValidationDataSource implements RemoteExtensionIndexDataSource {
  @override
  Future<RemoteExtensionIndexModel> fetchRepositoryIndex(
    Uri repositoryUri,
  ) async {
    return RemoteExtensionIndexModel.fromMap(<String, Object?>{
      'schemaVersion': 1,
      'extensions': <Object?>[
        <String, Object?>{
          'name': 'MangaDex',
          'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
          'versionName': '1.0.0',
          'installArtifact': 'https://repo.example/mangadex.apk',
        },
      ],
    });
  }
}

class _FailValidationDataSource implements RemoteExtensionIndexDataSource {
  @override
  Future<RemoteExtensionIndexModel> fetchRepositoryIndex(
    Uri repositoryUri,
  ) async {
    throw const RemoteExtensionIndexInvalidFormatException('invalid index');
  }
}

class _UnreachableValidationDataSource
    implements RemoteExtensionIndexDataSource {
  @override
  Future<RemoteExtensionIndexModel> fetchRepositoryIndex(
    Uri repositoryUri,
  ) async {
    throw const RemoteExtensionIndexUnreachableException('network down');
  }
}

void main() {
  const RepositoryConfig repository = RepositoryConfig(
    id: 'repo-1',
    displayName: 'Primary',
    baseUrl:
        'https://raw.githubusercontent.com/yuzono/manga-repo/repo/index.min.json',
    isEnabled: true,
    healthStatus: RepositoryHealthStatus.unknown,
  );

  group('SettingsController.validateRepository', () {
    test(
      'marks repository healthy when remote index validation succeeds',
      () async {
        final _FakeSettingsRepository fakeRepository = _FakeSettingsRepository(
          <RepositoryConfig>[repository],
        );

        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            settingsRepositoryProvider.overrideWithValue(fakeRepository),
            repositoryValidationDataSourceProvider.overrideWithValue(
              _SuccessValidationDataSource(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(settingsControllerProvider.notifier)
            .validateRepository(repository.id);

        final SettingsSnapshot snapshot = await container.read(
          settingsControllerProvider.future,
        );

        expect(snapshot.repositories, hasLength(1));
        expect(
          snapshot.repositories.first.healthStatus,
          RepositoryHealthStatus.healthy,
        );
        expect(snapshot.repositories.first.lastValidatedAt, isNotNull);
        expect(
          container.read(settingsOperationFeedbackProvider),
          AppStrings.settingsRepositoryValidationSuccess,
        );
      },
    );

    test(
      'marks repository unhealthy when remote index validation fails',
      () async {
        final _FakeSettingsRepository fakeRepository = _FakeSettingsRepository(
          <RepositoryConfig>[repository],
        );

        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            settingsRepositoryProvider.overrideWithValue(fakeRepository),
            repositoryValidationDataSourceProvider.overrideWithValue(
              _FailValidationDataSource(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(settingsControllerProvider.notifier)
            .validateRepository(repository.id);

        final SettingsSnapshot snapshot = await container.read(
          settingsControllerProvider.future,
        );

        expect(snapshot.repositories, hasLength(1));
        expect(
          snapshot.repositories.first.healthStatus,
          RepositoryHealthStatus.unhealthy,
        );
        expect(snapshot.repositories.first.lastValidatedAt, isNotNull);
        expect(
          container.read(settingsOperationFeedbackProvider),
          AppStrings.settingsRepositoryValidationInvalidIndex,
        );
      },
    );

    test(
      'uses unreachable feedback when repository cannot be reached',
      () async {
        final _FakeSettingsRepository fakeRepository = _FakeSettingsRepository(
          <RepositoryConfig>[repository],
        );

        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            settingsRepositoryProvider.overrideWithValue(fakeRepository),
            repositoryValidationDataSourceProvider.overrideWithValue(
              _UnreachableValidationDataSource(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(settingsControllerProvider.notifier)
            .validateRepository(repository.id);

        final SettingsSnapshot snapshot = await container.read(
          settingsControllerProvider.future,
        );

        expect(snapshot.repositories, hasLength(1));
        expect(
          snapshot.repositories.first.healthStatus,
          RepositoryHealthStatus.unhealthy,
        );
        expect(
          container.read(settingsOperationFeedbackProvider),
          AppStrings.settingsRepositoryValidationUnreachable,
        );
      },
    );

    test('uses invalid-url feedback for unsupported schemes', () async {
      const RepositoryConfig invalidUrlRepository = RepositoryConfig(
        id: 'repo-invalid-url',
        displayName: 'Invalid URL',
        baseUrl: 'ftp://repo.example',
        isEnabled: true,
        healthStatus: RepositoryHealthStatus.unknown,
      );
      final _FakeSettingsRepository fakeRepository = _FakeSettingsRepository(
        <RepositoryConfig>[invalidUrlRepository],
      );

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          settingsRepositoryProvider.overrideWithValue(fakeRepository),
          repositoryValidationDataSourceProvider.overrideWithValue(
            _SuccessValidationDataSource(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(settingsControllerProvider.notifier)
          .validateRepository(invalidUrlRepository.id);

      final SettingsSnapshot snapshot = await container.read(
        settingsControllerProvider.future,
      );

      expect(snapshot.repositories, hasLength(1));
      expect(
        snapshot.repositories.first.healthStatus,
        RepositoryHealthStatus.unhealthy,
      );
      expect(
        container.read(settingsOperationFeedbackProvider),
        AppStrings.settingsRepositoryValidationInvalidUrl,
      );
    });
  });
}
