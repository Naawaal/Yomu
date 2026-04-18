import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/features/extensions/data/datasources/remote_extension_index_datasource.dart';
import 'package:yomu/features/extensions/data/models/remote_extension_index_model.dart';

class _FakeHttpClient implements RemoteExtensionIndexHttpClient {
  _FakeHttpClient({this.responseBody = '{}', this.error, this.responseQueue});

  final String responseBody;
  final Object? error;
  final List<Object?>? responseQueue;
  Uri? lastRequestedUri;
  int requestCount = 0;

  @override
  Future<String> get(Uri uri) async {
    requestCount += 1;
    lastRequestedUri = uri;

    if (responseQueue != null && responseQueue!.isNotEmpty) {
      final Object? next = responseQueue!.removeAt(0);
      if (next is String) {
        return next;
      }
      throw next!;
    }

    if (error != null) {
      throw error!;
    }
    return responseBody;
  }
}

void main() {
  group('RemoteExtensionIndexHttpDataSource.fetchRepositoryIndex', () {
    test('resolves index uri and parses repository payload', () async {
      final _FakeHttpClient client = _FakeHttpClient(
        responseBody: '''
{
  "schemaVersion": 1,
  "repositoryName": "Community Repo",
  "extensions": [
    {
      "name": "MangaDex",
      "packageName": "eu.kanade.tachiyomi.extension.all.mangadex",
      "language": "all",
      "versionName": "1.0.0",
      "installArtifact": "https://repo.example/mangadex.apk",
      "isNsfw": false
    }
  ]
}
''',
      );
      final RemoteExtensionIndexHttpDataSource dataSource =
          RemoteExtensionIndexHttpDataSource(httpClient: client);

      final RemoteExtensionIndexModel index = await dataSource
          .fetchRepositoryIndex(Uri.parse('https://repo.example/extensions/'));

      expect(
        client.lastRequestedUri.toString(),
        'https://repo.example/extensions/index.json',
      );
      expect(index.repositoryName, 'Community Repo');
      expect(index.extensions, hasLength(1));
    });

    test('parses Tachiyomi array-root payloads into normalized entries', () async {
      final _FakeHttpClient client = _FakeHttpClient(
        responseBody: '''
[
  {
    "name": "Tachiyomi: MangaDex",
    "pkg": "eu.kanade.tachiyomi.extension.all.mangadex",
    "apk": "tachiyomi-all.mangadex-v1.4.207.apk",
    "lang": "all",
    "version": "1.4.207",
    "nsfw": 1
  }
]
''',
      );
      final RemoteExtensionIndexHttpDataSource dataSource =
          RemoteExtensionIndexHttpDataSource(httpClient: client);

      final RemoteExtensionIndexModel
      index = await dataSource.fetchRepositoryIndex(
        Uri.parse(
          'https://raw.githubusercontent.com/yuzono/manga-repo/repo/index.min.json',
        ),
      );

      final RemoteExtensionEntryModel entry = index.extensions.single;
      expect(entry.name, 'Tachiyomi: MangaDex');
      expect(entry.packageName, 'eu.kanade.tachiyomi.extension.all.mangadex');
      expect(entry.versionName, '1.4.207');
      expect(entry.isNsfw, isTrue);
      expect(
        entry.installArtifact,
        'https://raw.githubusercontent.com/yuzono/manga-repo/repo/apk/tachiyomi-all.mangadex-v1.4.207.apk',
      );
    });

    test('retries on transient server error and then succeeds', () async {
      final _FakeHttpClient client = _FakeHttpClient(
        responseQueue: <Object?>[
          RemoteExtensionHttpStatusException(
            statusCode: 503,
            uri: Uri.parse('https://repo.example/index.json'),
          ),
          '''
{
  "schemaVersion": 1,
  "extensions": [
    {
      "name": "RetrySuccess",
      "packageName": "pkg.retry.success",
      "versionName": "1.0.0",
      "installArtifact": "https://repo.example/retry.apk"
    }
  ]
}
''',
        ],
      );
      final RemoteExtensionIndexHttpDataSource dataSource =
          RemoteExtensionIndexHttpDataSource(httpClient: client, maxRetries: 2);

      final RemoteExtensionIndexModel index = await dataSource
          .fetchRepositoryIndex(Uri.parse('https://repo.example'));

      expect(index.extensions, hasLength(1));
      expect(client.requestCount, 2);
    });

    test('does not retry on non-retryable client error status', () async {
      final _FakeHttpClient client = _FakeHttpClient(
        error: RemoteExtensionHttpStatusException(
          statusCode: 404,
          uri: Uri.parse('https://repo.example/index.json'),
        ),
      );
      final RemoteExtensionIndexHttpDataSource dataSource =
          RemoteExtensionIndexHttpDataSource(httpClient: client, maxRetries: 3);

      await expectLater(
        () =>
            dataSource.fetchRepositoryIndex(Uri.parse('https://repo.example')),
        throwsA(isA<RemoteExtensionIndexException>()),
      );

      expect(client.requestCount, 1);
    });

    test('throws when repository url scheme is unsupported', () async {
      final _FakeHttpClient client = _FakeHttpClient();
      final RemoteExtensionIndexHttpDataSource dataSource =
          RemoteExtensionIndexHttpDataSource(httpClient: client);

      await expectLater(
        () => dataSource.fetchRepositoryIndex(Uri.parse('git://repo.example')),
        throwsA(isA<RemoteExtensionIndexException>()),
      );
      expect(client.lastRequestedUri, isNull);
    });

    test(
      'throws when response root is neither an object nor an array',
      () async {
        final _FakeHttpClient client = _FakeHttpClient(responseBody: '123');
        final RemoteExtensionIndexHttpDataSource dataSource =
            RemoteExtensionIndexHttpDataSource(httpClient: client);

        await expectLater(
          () => dataSource.fetchRepositoryIndex(
            Uri.parse('https://repo.example'),
          ),
          throwsA(isA<RemoteExtensionIndexException>()),
        );
      },
    );

    test('wraps transport errors with repository context', () async {
      final _FakeHttpClient client = _FakeHttpClient(error: Exception('boom'));
      final RemoteExtensionIndexHttpDataSource dataSource =
          RemoteExtensionIndexHttpDataSource(httpClient: client);

      await expectLater(
        () =>
            dataSource.fetchRepositoryIndex(Uri.parse('https://repo.example')),
        throwsA(isA<RemoteExtensionIndexException>()),
      );
    });

    test(
      'returns cached value without additional requests inside TTL',
      () async {
        final _FakeHttpClient client = _FakeHttpClient(
          responseBody: '''
{
  "schemaVersion": 1,
  "extensions": [
    {
      "name": "Cached",
      "packageName": "pkg.cached",
      "versionName": "1.0.0",
      "installArtifact": "https://repo.example/cached.apk"
    }
  ]
}
''',
        );
        final RemoteExtensionIndexHttpDataSource dataSource =
            RemoteExtensionIndexHttpDataSource(
              httpClient: client,
              cacheTtl: const Duration(minutes: 10),
            );

        await dataSource.fetchRepositoryIndex(
          Uri.parse('https://repo.example'),
        );
        await dataSource.fetchRepositoryIndex(
          Uri.parse('https://repo.example'),
        );

        expect(client.requestCount, 1);
      },
    );
  });
}
