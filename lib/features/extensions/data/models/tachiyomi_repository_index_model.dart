import 'remote_extension_index_model.dart';

/// Parsed Tachiyomi-style repository index document.
class TachiyomiRepositoryIndexModel {
  /// Creates a typed Tachiyomi repository index document.
  const TachiyomiRepositoryIndexModel({
    required this.extensions,
    this.repositoryName,
  });

  /// Optional repository display name supplied by the caller.
  final String? repositoryName;

  /// Normalized remote extension entries.
  final List<RemoteExtensionEntryModel> extensions;

  /// Creates a Tachiyomi repository index from a decoded JSON-like list.
  factory TachiyomiRepositoryIndexModel.fromList(
    List<Object?> values, {
    String? repositoryName,
    required String Function(String apkFileName) resolveInstallArtifact,
  }) {
    return TachiyomiRepositoryIndexModel(
      repositoryName: repositoryName,
      extensions: values
          .map(_TachiyomiRepositoryEntryModel.fromObject)
          .map(
            (_TachiyomiRepositoryEntryModel entry) =>
                entry.toRemoteExtensionEntry(
                  resolveInstallArtifact: resolveInstallArtifact,
                ),
          )
          .toList(growable: false),
    );
  }
}

class _TachiyomiRepositoryEntryModel {
  const _TachiyomiRepositoryEntryModel({
    required this.name,
    required this.packageName,
    required this.language,
    required this.versionName,
    required this.apkFileName,
    required this.isNsfw,
  });

  final String name;
  final String packageName;
  final String language;
  final String versionName;
  final String apkFileName;
  final bool isNsfw;

  factory _TachiyomiRepositoryEntryModel.fromObject(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const RemoteExtensionIndexException(
        'Each Tachiyomi repository entry must be an object.',
      );
    }

    final Map<String, Object?> map = value.map(
      (Object? key, Object? item) => MapEntry(key.toString(), item),
    );

    return _TachiyomiRepositoryEntryModel(
      name: _requireNonEmptyString(map, 'name'),
      packageName: _requireNonEmptyString(map, 'pkg'),
      language: _readNonEmptyString(map['lang']) ?? 'all',
      versionName: _requireNonEmptyString(map, 'version'),
      apkFileName: _requireNonEmptyString(map, 'apk'),
      isNsfw: _readBoolLike(map['nsfw']) ?? false,
    );
  }

  RemoteExtensionEntryModel toRemoteExtensionEntry({
    required String Function(String apkFileName) resolveInstallArtifact,
  }) {
    return RemoteExtensionEntryModel(
      name: name,
      packageName: packageName,
      language: language,
      versionName: versionName,
      installArtifact: resolveInstallArtifact(apkFileName),
      isNsfw: isNsfw,
    );
  }
}

String _requireNonEmptyString(Map<String, Object?> map, String key) {
  final String? value = _readNonEmptyString(map[key]);
  if (value == null) {
    throw RemoteExtensionIndexException(
      'Tachiyomi repository entry field `$key` is required.',
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

bool? _readBoolLike(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is int) {
    return value != 0;
  }

  if (value is String) {
    final String normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }

  return null;
}
