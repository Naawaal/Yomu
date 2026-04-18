import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/features/extensions/data/datasources/remote_extension_index_datasource.dart';
import 'package:yomu/features/extensions/data/models/remote_extension_index_model.dart';
import 'package:yomu/features/extensions/data/repositories/remote_extension_catalog_repository_impl.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/settings/domain/entities/repository_config.dart';
import 'package:yomu/features/settings/domain/entities/settings_snapshot.dart';
import 'package:yomu/features/settings/domain/repositories/settings_repository.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.repositories);

  final List<RepositoryConfig> repositories;

  @override
  Future<List<RepositoryConfig>> addRepository(RepositoryConfig repository) {
    throw UnimplementedError();
  }

  @override
  Future<BackupSnapshot> exportBackup() {
    throw UnimplementedError();
  }

  @override
  Future<List<RepositoryConfig>> getRepositories() async => repositories;

  @override
  Future<SettingsSnapshot> getSettingsSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<BackupSnapshot> importBackup() {
    throw UnimplementedError();
  }

  @override
  Future<List<RepositoryConfig>> removeRepository(String repositoryId) {
    throw UnimplementedError();
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) {
    throw UnimplementedError();
  }

  @override
  Future<List<RepositoryConfig>> updateRepository(RepositoryConfig repository) {
    throw UnimplementedError();
  }

  @override
  Future<RepositoryConfig> validateRepository(String repositoryId) {
    throw UnimplementedError();
  }
}

class _FakeRemoteDataSource implements RemoteExtensionIndexDataSource {
  _FakeRemoteDataSource(this.responses);

  final Map<String, RemoteExtensionIndexModel> responses;

  @override
  Future<RemoteExtensionIndexModel> fetchRepositoryIndex(
    Uri repositoryUri,
  ) async {
    final RemoteExtensionIndexModel? value =
        responses[repositoryUri.toString()];
    if (value == null) {
      throw const RemoteExtensionIndexException('missing test response');
    }
    return value;
  }
}

void main() {
  group('RemoteExtensionCatalogRepositoryImpl.getRemoteExtensions', () {
    const RepositoryConfig enabled = RepositoryConfig(
      id: 'repo-enabled',
      displayName: 'Enabled',
      baseUrl: 'https://repo.example',
      isEnabled: true,
      healthStatus: RepositoryHealthStatus.healthy,
    );
    const RepositoryConfig disabled = RepositoryConfig(
      id: 'repo-disabled',
      displayName: 'Disabled',
      baseUrl: 'https://disabled.example',
      isEnabled: false,
      healthStatus: RepositoryHealthStatus.healthy,
    );

    test('returns entries from enabled repositories', () async {
      final RemoteExtensionCatalogRepositoryImpl
      repository = RemoteExtensionCatalogRepositoryImpl(
        settingsRepository: _FakeSettingsRepository(<RepositoryConfig>[
          enabled,
          disabled,
        ]),
        dataSource: _FakeRemoteDataSource(<String, RemoteExtensionIndexModel>{
          'https://repo.example': RemoteExtensionIndexModel.fromMap(
            <String, Object?>{
              'schemaVersion': 1,
              'extensions': <Object?>[
                <String, Object?>{
                  'name': 'MangaDex',
                  'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
                  'language': 'all',
                  'versionName': '1.0.0',
                  'installArtifact': 'https://repo.example/mangadex.apk',
                },
              ],
            },
          ),
        }),
      );

      final List<ExtensionItem> items = await repository.getRemoteExtensions();

      expect(items, hasLength(1));
      expect(items.first.name, 'MangaDex');
      expect(items.first.trustStatus, ExtensionTrustStatus.untrusted);
    });

    test(
      'continues returning valid entries when another repository fails',
      () async {
        final RemoteExtensionCatalogRepositoryImpl
        repository = RemoteExtensionCatalogRepositoryImpl(
          settingsRepository: _FakeSettingsRepository(<RepositoryConfig>[
            enabled,
            const RepositoryConfig(
              id: 'repo-invalid',
              displayName: 'Invalid',
              baseUrl: 'https://invalid.example',
              isEnabled: true,
              healthStatus: RepositoryHealthStatus.healthy,
            ),
          ]),
          dataSource: _FakeRemoteDataSource(<String, RemoteExtensionIndexModel>{
            'https://repo.example': RemoteExtensionIndexModel.fromMap(
              <String, Object?>{
                'schemaVersion': 1,
                'extensions': <Object?>[
                  <String, Object?>{
                    'name': 'MangaDex',
                    'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
                    'versionName': '1.0.0',
                    'installArtifact': 'https://repo.example/mangadex.apk',
                  },
                ],
              },
            ),
          }),
        );

        final List<ExtensionItem> items = await repository
            .getRemoteExtensions();

        expect(items, hasLength(1));
        expect(items.first.name, 'MangaDex');
      },
    );

    test('deduplicates entries by packageName across repositories', () async {
      final RemoteExtensionCatalogRepositoryImpl
      repository = RemoteExtensionCatalogRepositoryImpl(
        settingsRepository: _FakeSettingsRepository(<RepositoryConfig>[
          enabled,
          const RepositoryConfig(
            id: 'repo-2',
            displayName: 'Second',
            baseUrl: 'https://repo2.example',
            isEnabled: true,
            healthStatus: RepositoryHealthStatus.healthy,
          ),
        ]),
        dataSource: _FakeRemoteDataSource(<String, RemoteExtensionIndexModel>{
          'https://repo.example': RemoteExtensionIndexModel.fromMap(
            <String, Object?>{
              'schemaVersion': 1,
              'extensions': <Object?>[
                <String, Object?>{
                  'name': 'MangaDex',
                  'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
                  'versionName': '1.0.0',
                  'installArtifact': 'https://repo.example/mangadex.apk',
                },
              ],
            },
          ),
          'https://repo2.example': RemoteExtensionIndexModel.fromMap(
            <String, Object?>{
              'schemaVersion': 1,
              'extensions': <Object?>[
                <String, Object?>{
                  'name': 'MangaDex Alt',
                  'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
                  'versionName': '2.0.0',
                  'installArtifact': 'https://repo2.example/mangadex.apk',
                },
              ],
            },
          ),
        }),
      );

      final List<ExtensionItem> items = await repository.getRemoteExtensions();

      expect(items, hasLength(1));
      expect(
        items.first.packageName,
        'eu.kanade.tachiyomi.extension.all.mangadex',
      );
    });
  });
}
