import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/features/extensions/data/models/remote_extension_index_model.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';

void main() {
  group('RemoteExtensionIndexFetchRules.resolveIndexUri', () {
    test('appends index.json when repository points to a directory', () {
      final Uri resolved = RemoteExtensionIndexFetchRules.resolveIndexUri(
        Uri.parse('https://repo.example/extensions/'),
      );

      expect(resolved.toString(), 'https://repo.example/extensions/index.json');
    });

    test('uses configured URI directly when it already targets json', () {
      final Uri resolved = RemoteExtensionIndexFetchRules.resolveIndexUri(
        Uri.parse('https://repo.example/catalog.json'),
      );

      expect(resolved.toString(), 'https://repo.example/catalog.json');
    });

    test('normalizes GitHub tree URL into raw compact index URL', () {
      final Uri resolved = RemoteExtensionIndexFetchRules.resolveIndexUri(
        Uri.parse('https://github.com/yuzono/manga-repo/tree/main/repo'),
      );

      expect(
        resolved.toString(),
        'https://raw.githubusercontent.com/yuzono/manga-repo/main/repo/index.min.json',
      );
    });

    test('normalizes GitHub blob JSON URL into raw URL', () {
      final Uri resolved = RemoteExtensionIndexFetchRules.resolveIndexUri(
        Uri.parse(
          'https://github.com/yuzono/manga-repo/blob/main/repo/index.min.json',
        ),
      );

      expect(
        resolved.toString(),
        'https://raw.githubusercontent.com/yuzono/manga-repo/main/repo/index.min.json',
      );
    });
  });

  group('RemoteExtensionIndexModel.fromMap', () {
    test('parses valid repository index payload', () {
      final RemoteExtensionIndexModel index = RemoteExtensionIndexModel.fromMap(
        <String, Object?>{
          'schemaVersion': 1,
          'repositoryName': 'Community Repo',
          'extensions': <Object?>[
            <String, Object?>{
              'name': 'MangaDex',
              'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
              'language': 'all',
              'versionName': '1.0.0',
              'installArtifact': 'https://repo.example/mangadex.apk',
              'iconUrl': 'https://repo.example/mangadex.png',
              'isNsfw': false,
            },
          ],
        },
      );

      expect(index.schemaVersion, 1);
      expect(index.repositoryName, 'Community Repo');
      expect(index.extensions, hasLength(1));
      expect(index.extensions.first.installArtifact, isNotEmpty);
      expect(
        index.extensions.first.iconUrl,
        'https://repo.example/mangadex.png',
      );
    });

    test('throws when schema version is unsupported', () {
      expect(
        () => RemoteExtensionIndexModel.fromMap(<String, Object?>{
          'schemaVersion': 99,
          'extensions': <Object?>[],
        }),
        throwsA(isA<RemoteExtensionIndexException>()),
      );
    });

    test('throws when extensions array is missing', () {
      expect(
        () => RemoteExtensionIndexModel.fromMap(<String, Object?>{
          'schemaVersion': 1,
        }),
        throwsA(isA<RemoteExtensionIndexException>()),
      );
    });
  });

  group('RemoteExtensionEntryModel', () {
    test('defaults language to all when omitted', () {
      final RemoteExtensionEntryModel entry =
          RemoteExtensionEntryModel.fromObject(<String, Object?>{
            'name': 'NekoScans',
            'packageName': 'eu.kanade.tachiyomi.extension.en.nekoscans',
            'versionName': '2.0.0',
            'installArtifact': 'https://repo.example/nekoscans.apk',
          });

      expect(entry.language, 'all');
      expect(entry.isNsfw, isFalse);
    });

    test('resolves relative iconUrl against repositoryUri', () {
      final RemoteExtensionEntryModel entry =
          RemoteExtensionEntryModel.fromObject(<String, Object?>{
            'name': 'MangaDex',
            'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
            'versionName': '1.0.0',
            'installArtifact': 'mangadex.apk',
            'iconUrl': 'icons/mangadex.png',
          });

      final ExtensionItem item = entry.toExtensionItem(
        trustStatus: ExtensionTrustStatus.untrusted,
        hasUpdate: false,
        repositoryUri: Uri.parse('https://repo.example/catalog/index.json'),
      );

      expect(item.iconUrl, 'https://repo.example/catalog/icons/mangadex.png');
    });

    test('keeps absolute iconUrl unchanged when repositoryUri is provided', () {
      final RemoteExtensionEntryModel entry =
          RemoteExtensionEntryModel.fromObject(<String, Object?>{
            'name': 'MangaDex',
            'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
            'versionName': '1.0.0',
            'installArtifact': 'https://repo.example/mangadex.apk',
            'iconUrl': 'https://cdn.example/icons/mangadex.png',
          });

      final ExtensionItem item = entry.toExtensionItem(
        trustStatus: ExtensionTrustStatus.untrusted,
        hasUpdate: false,
        repositoryUri: Uri.parse('https://repo.example/catalog/index.json'),
      );

      expect(item.iconUrl, 'https://cdn.example/icons/mangadex.png');
    });

    test(
      'resolves relative installArtifact when repositoryUri is provided',
      () {
        final RemoteExtensionEntryModel entry =
            RemoteExtensionEntryModel.fromObject(<String, Object?>{
              'name': 'MangaDex',
              'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
              'versionName': '1.0.0',
              'installArtifact': 'downloads/mangadex.apk',
            });

        final ExtensionItem item = entry.toExtensionItem(
          trustStatus: ExtensionTrustStatus.untrusted,
          hasUpdate: false,
          repositoryUri: Uri.parse('https://repo.example/catalog/index.json'),
        );

        expect(
          item.installArtifact,
          'https://repo.example/catalog/downloads/mangadex.apk',
        );
      },
    );

    test('throws when installArtifact is missing', () {
      expect(
        () => RemoteExtensionEntryModel.fromObject(<String, Object?>{
          'name': 'Broken',
          'packageName': 'pkg.broken',
          'versionName': '0.0.1',
        }),
        throwsA(isA<RemoteExtensionIndexException>()),
      );
    });

    test('maps into ExtensionItem for later composition', () {
      final RemoteExtensionEntryModel entry =
          RemoteExtensionEntryModel.fromObject(<String, Object?>{
            'name': 'MangaDex',
            'packageName': 'eu.kanade.tachiyomi.extension.all.mangadex',
            'language': 'all',
            'versionName': '1.0.0',
            'installArtifact': 'https://repo.example/mangadex.apk',
            'icon_url': 'https://repo.example/mangadex.png',
            'isNsfw': false,
          });

      final ExtensionItem item = entry.toExtensionItem(
        trustStatus: ExtensionTrustStatus.untrusted,
        hasUpdate: false,
      );

      expect(item.name, entry.name);
      expect(item.installArtifact, entry.installArtifact);
      expect(item.iconUrl, 'https://repo.example/mangadex.png');
      expect(item.trustStatus, ExtensionTrustStatus.untrusted);
    });
  });
}
