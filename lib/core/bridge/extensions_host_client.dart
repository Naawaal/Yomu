import 'package:flutter/services.dart';

/// Canonical capability identifiers exposed by the native extension host.
abstract final class ExtensionsHostCapabilities {
  /// Host supports listing available extensions.
  static const String listAvailable = 'extensions.list';

  /// Host supports trusting extensions.
  static const String trust = 'extensions.trust';

  /// Host supports extension install flow.
  static const String install = 'extensions.install';

  /// Host supports runtime execution for latest updates.
  static const String executeLatest = 'extensions.execute.latest';

  /// Host supports runtime execution for popular listings.
  static const String executePopular = 'extensions.execute.popular';

  /// Host supports runtime execution for search listings.
  static const String executeSearch = 'extensions.execute.search';

  /// Legacy capability used by older hosts.
  static const String legacyListAvailable = 'extensions.list.available';

  /// Legacy capability alias used by older hosts.
  static const String legacyListAvailableMethod = 'listAvailableExtensions';
}

/// Runtime capability information from the native extension host.
class ExtensionsHostRuntimeInfo {
  /// Creates runtime info.
  const ExtensionsHostRuntimeInfo({
    required this.schemaVersion,
    required this.capabilities,
  });

  /// Bridge schema version.
  final int schemaVersion;

  /// Supported capability identifiers.
  final Set<String> capabilities;

  /// Creates runtime info from a platform map.
  factory ExtensionsHostRuntimeInfo.fromMap(Map<String, Object?> map) {
    final Object? schema = map['schemaVersion'];
    final Object? capabilities = map['capabilities'];

    return ExtensionsHostRuntimeInfo(
      schemaVersion: schema is int ? schema : 1,
      capabilities: capabilities is List<Object?>
          ? capabilities.whereType<String>().toSet()
          : <String>{},
    );
  }
}

/// Raw extension payload received from the native extension host.
class HostExtensionPayload {
  /// Creates extension payload.
  const HostExtensionPayload({
    required this.name,
    required this.packageName,
    required this.language,
    required this.versionName,
    required this.hasUpdate,
    required this.isNsfw,
    required this.isTrusted,
    this.installArtifact,
    this.iconUrl,
  });

  /// Extension display name.
  final String name;

  /// Extension package name.
  final String packageName;

  /// Language code.
  final String language;

  /// Version name.
  final String versionName;

  /// Whether an update exists.
  final bool hasUpdate;

  /// Whether extension is NSFW.
  final bool isNsfw;

  /// Whether extension is trusted.
  final bool isTrusted;

  /// Optional install artifact hint for host install flow.
  final String? installArtifact;

  /// Optional icon URI to render for this extension entry.
  final String? iconUrl;

  /// Creates payload from map values.
  factory HostExtensionPayload.fromMap(Map<String, Object?> map) {
    return HostExtensionPayload(
      name: _readString(map, <String>['name']) ?? 'Unknown',
      packageName: _readString(map, <String>['packageName', 'pkg']) ?? '',
      language: _readString(map, <String>['language', 'lang']) ?? 'all',
      versionName:
          _readString(map, <String>['versionName', 'version']) ?? '0.0.0',
      hasUpdate: _readBool(map, <String>['hasUpdate', 'update']) ?? false,
      isNsfw: _readBool(map, <String>['isNsfw', 'nsfw']) ?? false,
      isTrusted: _readBool(map, <String>['isTrusted', 'trusted']) ?? false,
      installArtifact: _readString(map, <String>[
        'installArtifact',
        'installUri',
        'apkUri',
        'downloadUrl',
      ]),
      iconUrl: _readString(map, <String>[
        'iconUrl',
        'iconUri',
        'iconURI',
        'icon_url',
        'icon',
      ]),
    );
  }
}

/// Runtime execution operation supported by the host bridge.
enum HostSourceRuntimeOperation { latest, popular, search }

/// Lightweight manga payload returned by runtime source execution.
class HostSourceMangaPayload {
  /// Creates a source manga payload.
  const HostSourceMangaPayload({
    required this.id,
    required this.sourceId,
    required this.title,
    this.subtitle,
    this.thumbnailUrl,
  });

  /// Source-scoped stable manga identifier.
  final String id;

  /// Source identifier that produced this entry.
  final String sourceId;

  /// Human-readable title.
  final String title;

  /// Optional subtitle/secondary line.
  final String? subtitle;

  /// Optional thumbnail URL.
  final String? thumbnailUrl;

  /// Creates payload from map values.
  factory HostSourceMangaPayload.fromMap(Map<String, Object?> map) {
    return HostSourceMangaPayload(
      id: _readString(map, <String>['id', 'mangaId']) ?? '',
      sourceId: _readString(map, <String>['sourceId', 'source']) ?? '',
      title: _readString(map, <String>['title', 'name']) ?? 'Unknown',
      subtitle: _readString(map, <String>['subtitle', 'description']),
      thumbnailUrl: _readString(map, <String>[
        'thumbnailUrl',
        'thumbUrl',
        'imageUrl',
      ]),
    );
  }
}

/// Paged source runtime result returned by execute operations.
class HostSourceRuntimePageResult {
  /// Creates a paged source runtime result.
  const HostSourceRuntimePageResult({
    required this.sourceId,
    required this.items,
    required this.hasMore,
    this.nextPage,
    this.nextPageToken,
  });

  /// Source identifier for this page.
  final String sourceId;

  /// Returned manga entries.
  final List<HostSourceMangaPayload> items;

  /// Whether more pages are available.
  final bool hasMore;

  /// Next page index for number-based pagination.
  final int? nextPage;

  /// Next page cursor for token-based pagination.
  final String? nextPageToken;

  /// Creates result from bridge map values.
  factory HostSourceRuntimePageResult.fromMap(Map<String, Object?> map) {
    final List<HostSourceMangaPayload> items = (map['items'] is List<Object?>)
        ? (map['items'] as List<Object?>)
              .whereType<Map<Object?, Object?>>()
              .map(
                (Map<Object?, Object?> row) => HostSourceMangaPayload.fromMap(
                  row.map((Object? key, Object? value) {
                    return MapEntry(key.toString(), value);
                  }),
                ),
              )
              .toList(growable: false)
        : const <HostSourceMangaPayload>[];

    return HostSourceRuntimePageResult(
      sourceId: _readString(map, <String>['sourceId']) ?? '',
      items: items,
      hasMore: _readBool(map, <String>['hasMore']) ?? false,
      nextPage: _readInt(map, <String>['nextPage']),
      nextPageToken: _readString(map, <String>['nextPageToken']),
    );
  }
}

/// Extension host API used by data layer repositories.
abstract class ExtensionsHostClient {
  /// Returns host runtime metadata used for capability checks.
  Future<ExtensionsHostRuntimeInfo> getRuntimeInfo();

  /// Returns available extensions from native host.
  Future<List<HostExtensionPayload>> listAvailableExtensions();

  /// Trusts an extension package.
  Future<void> trustExtension(String packageName);

  /// Installs an extension package.
  Future<HostInstallResult> installExtension(
    String packageName, {
    String? installArtifact,
  });

  /// Executes latest-updates runtime query against a trusted source.
  Future<HostSourceRuntimePageResult> executeLatest({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) {
    return Future<HostSourceRuntimePageResult>.error(
      UnsupportedError('executeLatest is not implemented by this host client.'),
    );
  }

  /// Executes popular-list runtime query against a trusted source.
  Future<HostSourceRuntimePageResult> executePopular({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) {
    return Future<HostSourceRuntimePageResult>.error(
      UnsupportedError(
        'executePopular is not implemented by this host client.',
      ),
    );
  }

  /// Executes search runtime query against a trusted source.
  Future<HostSourceRuntimePageResult> executeSearch({
    required String sourceId,
    required String query,
    int page = 1,
    int pageSize = 20,
  }) {
    return Future<HostSourceRuntimePageResult>.error(
      UnsupportedError('executeSearch is not implemented by this host client.'),
    );
  }
}

/// Typed install state values returned by the native extension host.
enum HostInstallState {
  /// Install session was committed to PackageInstaller.
  committed,

  /// User action is required before install can proceed.
  requiresUserAction,
}

/// Structured install result returned from native install requests.
class HostInstallResult {
  /// Creates install result.
  const HostInstallResult({
    required this.state,
    required this.message,
    this.sessionId,
  });

  /// Install state.
  final HostInstallState state;

  /// Optional install session identifier.
  final int? sessionId;

  /// Human-readable status message.
  final String message;

  /// Creates install result from bridge map.
  factory HostInstallResult.fromMap(Map<String, Object?> map) {
    final String rawState =
        _readString(map, <String>['state']) ?? _HostInstallStates.committed;
    final HostInstallState state;

    switch (rawState) {
      case _HostInstallStates.requiresUserAction:
        state = HostInstallState.requiresUserAction;
      case _HostInstallStates.committed:
      default:
        state = HostInstallState.committed;
    }

    return HostInstallResult(
      state: state,
      sessionId: _readInt(map, <String>['sessionId']),
      message:
          _readString(map, <String>['message']) ?? 'Install request submitted.',
    );
  }
}

/// MethodChannel implementation for Android extension host bridge.
class MethodChannelExtensionsHostClient implements ExtensionsHostClient {
  /// Creates a channel-backed extension host client.
  MethodChannelExtensionsHostClient({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'yomu/extensions';
  static const int _requiredSchemaVersion = 1;

  final MethodChannel _channel;

  @override
  Future<ExtensionsHostRuntimeInfo> getRuntimeInfo() async {
    final Map<String, Object?> result = await _invokeMapMethod(
      _BridgeMethods.getRuntimeInfo,
    );
    final ExtensionsHostRuntimeInfo runtimeInfo =
        ExtensionsHostRuntimeInfo.fromMap(result);

    if (runtimeInfo.schemaVersion < _requiredSchemaVersion) {
      throw PlatformException(
        code: 'SCHEMA_UNSUPPORTED',
        message: 'Host schema version is older than required',
      );
    }
    return runtimeInfo;
  }

  @override
  Future<List<HostExtensionPayload>> listAvailableExtensions() async {
    final List<Map<String, Object?>> rows = await _invokeListOfMapsMethod(
      _BridgeMethods.listAvailableExtensions,
    );
    return rows.map(HostExtensionPayload.fromMap).toList(growable: false);
  }

  @override
  Future<void> trustExtension(String packageName) async {
    await _channel.invokeMethod<void>(
      _BridgeMethods.trustExtension,
      <String, Object?>{'packageName': packageName},
    );
  }

  @override
  Future<HostInstallResult> installExtension(
    String packageName, {
    String? installArtifact,
  }) async {
    final Map<String, Object?> result = await _invokeMapMethod(
      _BridgeMethods.installExtension,
      <String, Object?>{
        'packageName': packageName,
        'installArtifact': installArtifact,
      },
    );
    return HostInstallResult.fromMap(result);
  }

  @override
  Future<HostSourceRuntimePageResult> executeLatest({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, Object?> result = await _invokeMapMethod(
      _BridgeMethods.executeLatest,
      <String, Object?>{
        'sourceId': sourceId,
        'page': page,
        'pageSize': pageSize,
      },
    );

    return HostSourceRuntimePageResult.fromMap(result);
  }

  @override
  Future<HostSourceRuntimePageResult> executePopular({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, Object?> result = await _invokeMapMethod(
      _BridgeMethods.executePopular,
      <String, Object?>{
        'sourceId': sourceId,
        'page': page,
        'pageSize': pageSize,
      },
    );

    return HostSourceRuntimePageResult.fromMap(result);
  }

  @override
  Future<HostSourceRuntimePageResult> executeSearch({
    required String sourceId,
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, Object?> result = await _invokeMapMethod(
      _BridgeMethods.executeSearch,
      <String, Object?>{
        'sourceId': sourceId,
        'query': query,
        'page': page,
        'pageSize': pageSize,
      },
    );

    return HostSourceRuntimePageResult.fromMap(result);
  }

  Future<Map<String, Object?>> _invokeMapMethod(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final Object? raw = await _channel.invokeMethod<Object?>(method, arguments);
    if (raw is Map<Object?, Object?>) {
      return raw.map((Object? key, Object? value) {
        return MapEntry(key.toString(), value);
      });
    }
    return <String, Object?>{};
  }

  Future<List<Map<String, Object?>>> _invokeListOfMapsMethod(
    String method,
  ) async {
    final Object? raw = await _channel.invokeMethod<Object?>(method);
    if (raw is List<Object?>) {
      return raw
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> row) {
            return row.map((Object? key, Object? value) {
              return MapEntry(key.toString(), value);
            });
          })
          .toList(growable: false);
    }
    return <Map<String, Object?>>[];
  }
}

abstract final class _BridgeMethods {
  static const String getRuntimeInfo = 'getRuntimeInfo';
  static const String listAvailableExtensions = 'listAvailableExtensions';
  static const String trustExtension = 'trustExtension';
  static const String installExtension = 'installExtension';
  static const String executeLatest = 'executeLatest';
  static const String executePopular = 'executePopular';
  static const String executeSearch = 'executeSearch';
}

String? _readString(Map<String, Object?> map, List<String> keys) {
  for (final String key in keys) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

bool? _readBool(Map<String, Object?> map, List<String> keys) {
  for (final String key in keys) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value == 1;
    }
  }
  return null;
}

int? _readInt(Map<String, Object?> map, List<String> keys) {
  for (final String key in keys) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
  }
  return null;
}

abstract final class _HostInstallStates {
  static const String committed = 'committed';
  static const String requiresUserAction = 'requires_user_action';
}
