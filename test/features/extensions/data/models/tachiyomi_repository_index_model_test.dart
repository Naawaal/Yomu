import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/features/extensions/data/models/remote_extension_index_model.dart';
import 'package:yomu/features/extensions/data/models/tachiyomi_repository_index_model.dart';

void main() {
  group('TachiyomiRepositoryIndexModel', () {
    test('normalizes alias fields into remote extension entries', () {
      final TachiyomiRepositoryIndexModel index =
          TachiyomiRepositoryIndexModel.fromList(
            <Object?>[
              <String, Object?>{
                'name': 'Tachiyomi: MangaDex',
                'pkg': 'eu.kanade.tachiyomi.extension.all.mangadex',
                'apk': 'tachiyomi-all.mangadex-v1.4.207.apk',
                'lang': 'all',
                'version': '1.4.207',
                'nsfw': 1,
              },
            ],
            resolveInstallArtifact: (String apkFileName) =>
                'https://example.com/apk/$apkFileName',
          );

      final RemoteExtensionEntryModel entry = index.extensions.single;
      expect(entry.name, 'Tachiyomi: MangaDex');
      expect(entry.packageName, 'eu.kanade.tachiyomi.extension.all.mangadex');
      expect(entry.language, 'all');
      expect(entry.versionName, '1.4.207');
      expect(
        entry.installArtifact,
        'https://example.com/apk/tachiyomi-all.mangadex-v1.4.207.apk',
      );
      expect(entry.isNsfw, isTrue);
    });

    test('throws when required alias fields are missing', () {
      expect(
        () => TachiyomiRepositoryIndexModel.fromList(<Object?>[
          <String, Object?>{
            'name': 'Tachiyomi: MangaDex',
            'apk': 'tachiyomi-all.mangadex-v1.4.207.apk',
            'version': '1.4.207',
          },
        ], resolveInstallArtifact: (String apkFileName) => apkFileName),
        throwsA(isA<RemoteExtensionIndexException>()),
      );
    });
  });

  group('RemoteExtensionIndexFetchRules.resolveTachiyomiInstallArtifact', () {
    test('uses apk directory for bare filenames from json urls', () {
      final String
      resolved = RemoteExtensionIndexFetchRules.resolveTachiyomiInstallArtifact(
        Uri.parse(
          'https://raw.githubusercontent.com/yuzono/manga-repo/repo/index.min.json',
        ),
        'tachiyomi-all.mangadex-v1.4.207.apk',
      );

      expect(
        resolved,
        'https://raw.githubusercontent.com/yuzono/manga-repo/repo/apk/tachiyomi-all.mangadex-v1.4.207.apk',
      );
    });

    test('keeps absolute artifact urls unchanged', () {
      const String artifactUrl = 'https://example.com/files/ext.apk';

      final String resolved =
          RemoteExtensionIndexFetchRules.resolveTachiyomiInstallArtifact(
            Uri.parse('https://example.com/repo/index.min.json'),
            artifactUrl,
          );

      expect(resolved, artifactUrl);
    });
  });
}
