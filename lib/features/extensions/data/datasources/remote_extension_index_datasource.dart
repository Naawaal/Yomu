import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/remote_extension_index_model.dart';
import '../models/tachiyomi_repository_index_model.dart';

/// Contract for loading a remote extension index document.
abstract class RemoteExtensionIndexDataSource {
  /// Fetches and parses a repository index from the provided repository URI.
  Future<RemoteExtensionIndexModel> fetchRepositoryIndex(Uri repositoryUri);
}

/// HTTP boundary used by the remote index datasource.
abstract class RemoteExtensionIndexHttpClient {
  /// Executes a GET request and returns the raw response body.
  Future<String> get(Uri uri);
}

/// HTTP status failure for remote extension index requests.
class RemoteExtensionHttpStatusException implements Exception {
  /// Creates an HTTP status exception.
  const RemoteExtensionHttpStatusException({
    required this.statusCode,
    required this.uri,
  });

  /// HTTP status code received from the repository endpoint.
  final int statusCode;

  /// Requested index URI.
  final Uri uri;

  @override
  String toString() {
    return 'Repository request failed with HTTP $statusCode: $uri';
  }
}

/// Validation failure for unsupported repository URL schemes.
class RemoteExtensionIndexUnsupportedSchemeException
    extends RemoteExtensionIndexException {
  /// Creates an unsupported-scheme validation exception.
  const RemoteExtensionIndexUnsupportedSchemeException(super.message);
}

/// Validation failure for malformed repository index payloads.
class RemoteExtensionIndexInvalidFormatException
    extends RemoteExtensionIndexException {
  /// Creates an invalid-format validation exception.
  const RemoteExtensionIndexInvalidFormatException(super.message);
}

/// Validation failure for transport/reachability issues.
class RemoteExtensionIndexUnreachableException
    extends RemoteExtensionIndexException {
  /// Creates an unreachable-repository validation exception.
  const RemoteExtensionIndexUnreachableException(super.message);
}

/// Dart IO implementation for fetching repository index documents.
class DartIoRemoteExtensionIndexHttpClient
    implements RemoteExtensionIndexHttpClient {
  /// Creates an HTTP client implementation backed by [HttpClient].
  const DartIoRemoteExtensionIndexHttpClient();

  @override
  Future<String> get(Uri uri) async {
    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();
      final String body = await utf8.decoder.bind(response).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RemoteExtensionHttpStatusException(
          statusCode: response.statusCode,
          uri: uri,
        );
      }

      return body;
    } finally {
      client.close(force: true);
    }
  }
}

/// HTTP-backed datasource for remote extension repository indexes.
class RemoteExtensionIndexHttpDataSource
    implements RemoteExtensionIndexDataSource {
  /// Creates a datasource that fetches index JSON over HTTP.
  RemoteExtensionIndexHttpDataSource({
    required RemoteExtensionIndexHttpClient httpClient,
    this.maxRetries = 2,
    this.requestTimeout = const Duration(seconds: 10),
    this.cacheTtl = const Duration(minutes: 5),
    this.useStaleCacheOnError = true,
  }) : _httpClient = httpClient;

  final RemoteExtensionIndexHttpClient _httpClient;

  /// Maximum number of retries after the first failed attempt.
  final int maxRetries;

  /// Maximum duration for each HTTP request attempt.
  final Duration requestTimeout;

  /// Time-to-live for a successfully fetched repository index.
  final Duration cacheTtl;

  /// Whether to return stale cached data if network fetch fails.
  final bool useStaleCacheOnError;

  final Map<Uri, _RemoteIndexCacheEntry> _cache =
      <Uri, _RemoteIndexCacheEntry>{};

  @override
  Future<RemoteExtensionIndexModel> fetchRepositoryIndex(
    Uri repositoryUri,
  ) async {
    if (!_isSupportedScheme(repositoryUri.scheme)) {
      throw RemoteExtensionIndexUnsupportedSchemeException(
        'Repository URL must use http or https: $repositoryUri',
      );
    }

    final Uri indexUri = RemoteExtensionIndexFetchRules.resolveIndexUri(
      repositoryUri,
    );

    final _RemoteIndexCacheEntry? cached = _cache[indexUri];
    if (cached != null && !cached.isExpired(cacheTtl)) {
      return cached.index;
    }

    Object? lastError;
    final int attempts = maxRetries < 0 ? 1 : maxRetries + 1;

    for (int attempt = 0; attempt < attempts; attempt++) {
      try {
        final String rawBody = await _httpClient
            .get(indexUri)
            .timeout(requestTimeout);
        final Object? decoded = jsonDecode(rawBody);

        final RemoteExtensionIndexModel index = _parseRepositoryIndex(
          decoded,
          repositoryUri: repositoryUri,
        );
        _cache[indexUri] = _RemoteIndexCacheEntry(index: index);
        return index;
      } on TimeoutException catch (error) {
        lastError = error;
        if (attempt == attempts - 1) {
          break;
        }
      } on SocketException catch (error) {
        lastError = error;
        if (attempt == attempts - 1) {
          break;
        }
      } on RemoteExtensionHttpStatusException catch (error) {
        lastError = error;
        final bool retryable = error.statusCode >= 500;
        if (!retryable || attempt == attempts - 1) {
          break;
        }
      } on RemoteExtensionIndexException {
        rethrow;
      } on FormatException {
        throw RemoteExtensionIndexInvalidFormatException(
          'Repository index is not valid JSON: $indexUri',
        );
      } catch (error) {
        lastError = error;
        if (attempt == attempts - 1) {
          break;
        }
      }
    }

    if (useStaleCacheOnError && cached != null) {
      return cached.index;
    }

    throw RemoteExtensionIndexUnreachableException(
      'Failed to fetch repository index from $indexUri: $lastError',
    );
  }
}

bool _isSupportedScheme(String scheme) {
  return scheme == 'http' || scheme == 'https';
}

RemoteExtensionIndexModel _parseRepositoryIndex(
  Object? decoded, {
  required Uri repositoryUri,
}) {
  if (decoded is Map<Object?, Object?>) {
    final Map<String, Object?> map = decoded.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
    return RemoteExtensionIndexModel.fromMap(map);
  }

  if (decoded is List<Object?>) {
    final TachiyomiRepositoryIndexModel normalized =
        TachiyomiRepositoryIndexModel.fromList(
          decoded,
          resolveInstallArtifact: (String apkFileName) =>
              RemoteExtensionIndexFetchRules.resolveTachiyomiInstallArtifact(
                repositoryUri,
                apkFileName,
              ),
        );

    return RemoteExtensionIndexModel(
      schemaVersion: RemoteExtensionIndexFetchRules.schemaVersion,
      repositoryName: normalized.repositoryName,
      extensions: normalized.extensions,
    );
  }

  throw const RemoteExtensionIndexInvalidFormatException(
    'Repository index root must be a JSON object or array.',
  );
}

class _RemoteIndexCacheEntry {
  _RemoteIndexCacheEntry({required this.index}) : fetchedAt = DateTime.now();

  final RemoteExtensionIndexModel index;
  final DateTime fetchedAt;

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(fetchedAt) > ttl;
  }
}
