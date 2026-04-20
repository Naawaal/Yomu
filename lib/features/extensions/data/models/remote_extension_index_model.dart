import '../../domain/entities/extension_item.dart';

/// Exception thrown when a remote extension repository index is invalid.
class RemoteExtensionIndexException implements Exception {
  /// Creates an exception describing an invalid repository index.
  const RemoteExtensionIndexException(this.message);

  /// Human-readable validation failure.
  final String message;

  @override
  String toString() => message;
}

/// Canonical fetch rules for remote extension repository indexes.
abstract final class RemoteExtensionIndexFetchRules {
  /// Current repository index schema version.
  static const int schemaVersion = 1;

  /// Conventional filename expected at repository roots.
  static const String defaultIndexFileName = 'index.json';

  /// Common Tachiyomi/Mihon compact index file name.
  static const String compactIndexFileName = 'index.min.json';

  static const String _githubHost = 'github.com';
  static const String _githubRawHost = 'raw.githubusercontent.com';

  /// Resolves the concrete index URI from a configured repository base URI.
  ///
  /// Rules:
  /// - if the configured URI already points to a `.json` document, use it
  /// - otherwise append `index.json` to the configured path
  static Uri resolveIndexUri(Uri repositoryUri) {
    final Uri normalizedRepositoryUri = _normalizeRepositoryUri(repositoryUri);

    final String lastSegment = normalizedRepositoryUri.pathSegments.isEmpty
        ? ''
        : normalizedRepositoryUri.pathSegments.last;
    if (lastSegment.toLowerCase().endsWith('.json')) {
      return normalizedRepositoryUri;
    }

    final List<String> segments = <String>[
      ...normalizedRepositoryUri.pathSegments.where(
        (String segment) => segment.isNotEmpty,
      ),
      _preferredIndexFileName(normalizedRepositoryUri),
    ];

    return normalizedRepositoryUri.replace(
      pathSegments: segments,
      queryParameters: null,
      fragment: null,
    );
  }

  static String _preferredIndexFileName(Uri repositoryUri) {
    final String host = repositoryUri.host.toLowerCase();
    if (host == _githubHost || host == _githubRawHost) {
      return compactIndexFileName;
    }

    return defaultIndexFileName;
  }

  static Uri _normalizeRepositoryUri(Uri repositoryUri) {
    final String host = repositoryUri.host.toLowerCase();
    if (host != _githubHost) {
      return repositoryUri;
    }

    final List<String> segments = repositoryUri.pathSegments
        .where((String segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.length < 2) {
      return repositoryUri;
    }

    final String owner = segments[0];
    final String repo = segments[1];
    final bool hasStructuredPath = segments.length >= 4;
    if (!hasStructuredPath) {
      return repositoryUri;
    }

    final String section = segments[2].toLowerCase();
    if (section != 'blob' && section != 'tree') {
      return repositoryUri;
    }

    final List<String> remaining = segments.sublist(3);
    if (remaining.isEmpty) {
      return repositoryUri;
    }

    return Uri(
      scheme: 'https',
      host: _githubRawHost,
      pathSegments: <String>[owner, repo, ...remaining],
    );
  }

  /// Resolves a Tachiyomi APK filename or relative path into an install artifact.
  static String resolveTachiyomiInstallArtifact(
    Uri repositoryUri,
    String apkFileName,
  ) {
    final Uri? parsedArtifact = Uri.tryParse(apkFileName);
    if (parsedArtifact != null && parsedArtifact.hasScheme) {
      return parsedArtifact.toString();
    }

    final Uri repositoryRoot = _resolveRepositoryRootUri(repositoryUri);
    final List<String> artifactSegments = apkFileName
        .split('/')
        .where((String segment) => segment.isNotEmpty)
        .toList(growable: false);

    final List<String> resolvedSegments = <String>[
      ...repositoryRoot.pathSegments.where(
        (String segment) => segment.isNotEmpty,
      ),
      if (artifactSegments.length == 1) 'apk',
      ...artifactSegments,
    ];

    return repositoryRoot.replace(pathSegments: resolvedSegments).toString();
  }

  static Uri _resolveRepositoryRootUri(Uri repositoryUri) {
    final String lastSegment = repositoryUri.pathSegments.isEmpty
        ? ''
        : repositoryUri.pathSegments.last;
    if (!lastSegment.toLowerCase().endsWith('.json')) {
      return repositoryUri;
    }

    final List<String> segments = repositoryUri.pathSegments
        .where((String segment) => segment.isNotEmpty)
        .toList(growable: false);

    if (segments.isEmpty) {
      return repositoryUri.replace(pathSegments: const <String>[]);
    }

    return repositoryUri.replace(
      pathSegments: segments.take(segments.length - 1),
    );
  }
}

/// Parsed remote repository index document.
class RemoteExtensionIndexModel {
  /// Creates a typed repository index document.
  const RemoteExtensionIndexModel({
    required this.schemaVersion,
    required this.extensions,
    this.repositoryName,
  });

  /// Supported schema version for the index document.
  final int schemaVersion;

  /// Optional repository display name surfaced by the index.
  final String? repositoryName;

  /// Remote extension entries advertised by the repository.
  final List<RemoteExtensionEntryModel> extensions;

  /// Creates a repository index from a decoded JSON-like map.
  factory RemoteExtensionIndexModel.fromMap(Map<String, Object?> map) {
    final int schemaVersion = _readInt(map['schemaVersion']);
    if (schemaVersion != RemoteExtensionIndexFetchRules.schemaVersion) {
      throw RemoteExtensionIndexException(
        'Unsupported repository schema version: $schemaVersion.',
      );
    }

    final Object? rawExtensions = map['extensions'];
    if (rawExtensions is! List<Object?>) {
      throw const RemoteExtensionIndexException(
        'Repository index must contain an extensions array.',
      );
    }

    return RemoteExtensionIndexModel(
      schemaVersion: schemaVersion,
      repositoryName: _readNonEmptyString(map['repositoryName']),
      extensions: rawExtensions
          .map(RemoteExtensionEntryModel.fromObject)
          .toList(growable: false),
    );
  }
}

/// Single remote extension entry advertised by a repository index.
class RemoteExtensionEntryModel {
  /// Creates a remote extension entry.
  const RemoteExtensionEntryModel({
    required this.name,
    required this.packageName,
    required this.language,
    required this.versionName,
    required this.installArtifact,
    required this.isNsfw,
    this.iconUrl,
  });

  /// Human-readable extension name.
  final String name;

  /// Unique Android package name for install/trust mapping.
  final String packageName;

  /// Source language code.
  final String language;

  /// Remote repository version label.
  final String versionName;

  /// Installable artifact URI or path consumed by the native installer.
  final String installArtifact;

  /// Whether this entry should be marked as NSFW in UI.
  final bool isNsfw;

  /// Optional icon URI to render in the source catalog UI.
  final String? iconUrl;

  /// Creates a remote entry from a decoded list element.
  factory RemoteExtensionEntryModel.fromObject(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const RemoteExtensionIndexException(
        'Each repository entry must be an object.',
      );
    }

    final Map<String, Object?> map = value.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );

    final String name = _requireNonEmptyString(map, 'name');
    final String packageName = _requireNonEmptyString(map, 'packageName');
    final String versionName = _requireNonEmptyString(map, 'versionName');
    final String installArtifact = _requireNonEmptyString(
      map,
      'installArtifact',
    );

    return RemoteExtensionEntryModel(
      name: name,
      packageName: packageName,
      language: _readNonEmptyString(map['language']) ?? 'all',
      versionName: versionName,
      installArtifact: installArtifact,
      isNsfw: map['isNsfw'] as bool? ?? false,
      iconUrl:
          _readNonEmptyString(map['iconUrl']) ??
          _readNonEmptyString(map['iconUri']) ??
          _readNonEmptyString(map['iconURI']) ??
          _readNonEmptyString(map['icon_url']) ??
          _readNonEmptyString(map['icon']),
    );
  }

  /// Converts the remote entry into the shared extension item shape.
  ExtensionItem toExtensionItem({
    required ExtensionTrustStatus trustStatus,
    required bool hasUpdate,
    Uri? repositoryUri,
  }) {
    return ExtensionItem(
      name: name,
      packageName: packageName,
      language: language,
      versionName: versionName,
      isInstalled: false,
      hasUpdate: hasUpdate,
      isNsfw: isNsfw,
      trustStatus: trustStatus,
      installArtifact: _resolveRepositoryRelativeUri(
        repositoryUri,
        installArtifact,
      ),
      iconUrl: _resolveRepositoryRelativeUri(repositoryUri, iconUrl),
    );
  }
}

String? _resolveRepositoryRelativeUri(Uri? repositoryUri, String? value) {
  if (value == null) {
    return null;
  }

  final Uri? parsedUri = Uri.tryParse(value);
  if (parsedUri != null && parsedUri.hasScheme) {
    return value;
  }

  if (repositoryUri == null) {
    return value;
  }

  return repositoryUri.resolveUri(Uri.parse(value)).toString();
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? -1;
}

String _requireNonEmptyString(Map<String, Object?> map, String key) {
  final String? value = _readNonEmptyString(map[key]);
  if (value == null) {
    throw RemoteExtensionIndexException(
      'Repository entry field `$key` is required.',
    );
  }
  return value;
}

String? _readNonEmptyString(Object? value) {
  if (value is String) {
    final String trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}
