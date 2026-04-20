import 'package:flutter/services.dart';

import '../../../../core/bridge/extensions_host_client.dart';
import '../../../../core/failure.dart';
import '../../domain/entities/source_runtime_page.dart';
import '../../domain/entities/source_runtime_request.dart';
import '../parsers/default_source_runtime_page_parser.dart';
import '../parsers/source_runtime_page_parser.dart';

/// Typed bridge error for source runtime execution failures.
class SourceRuntimeBridgeException implements Exception {
  /// Creates a source runtime bridge exception.
  const SourceRuntimeBridgeException({
    required this.code,
    required this.message,
  });

  /// Stable machine-readable error code.
  final String code;

  /// Human-readable error message.
  final String message;

  @override
  String toString() => message;
}

/// Bridge datasource for runtime source execution.
abstract class SourceRuntimeBridgeDataSource {
  /// Executes one runtime request via native host bridge.
  Future<SourceRuntimePage> execute(SourceRuntimeRequest request);
}

/// MethodChannel-backed runtime bridge datasource.
class MethodChannelSourceRuntimeBridgeDataSource
    implements SourceRuntimeBridgeDataSource {
  /// Creates a bridge datasource for runtime source execution.
  const MethodChannelSourceRuntimeBridgeDataSource({
    required ExtensionsHostClient hostClient,
    SourceRuntimePageParser pageParser = const DefaultSourceRuntimePageParser(),
  }) : _hostClient = hostClient,
       _pageParser = pageParser;

  final ExtensionsHostClient _hostClient;
  final SourceRuntimePageParser _pageParser;

  @override
  Future<SourceRuntimePage> execute(SourceRuntimeRequest request) async {
    try {
      final ExtensionsHostRuntimeInfo runtimeInfo = await _hostClient
          .getRuntimeInfo();

      if (!_supportsOperation(runtimeInfo.capabilities, request.operation)) {
        throw SourceRuntimeBridgeException(
          code: SourceFailureCode.unsupportedCapability,
          message:
              'Runtime operation is not supported by this extension host: '
              '${request.operation.name}',
        );
      }

      final HostSourceRuntimePageResult result;
      switch (request.operation) {
        case SourceRuntimeOperation.latest:
          result = await _hostClient.executeLatest(
            sourceId: request.sourceId,
            page: request.page,
            pageSize: request.pageSize,
          );
        case SourceRuntimeOperation.popular:
          result = await _hostClient.executePopular(
            sourceId: request.sourceId,
            page: request.page,
            pageSize: request.pageSize,
          );
        case SourceRuntimeOperation.search:
          result = await _hostClient.executeSearch(
            sourceId: request.sourceId,
            query: request.query,
            page: request.page,
            pageSize: request.pageSize,
          );
      }

      return _pageParser.parse(hostPage: result, request: request);
    } on MissingPluginException {
      throw const SourceRuntimeBridgeException(
        code: SourceFailureCode.missingPlugin,
        message: 'Source runtime bridge is unavailable on this platform.',
      );
    } on PlatformException catch (exception) {
      throw SourceRuntimeBridgeException(
        code: exception.code,
        message: exception.message ?? 'Source runtime execution failed.',
      );
    }
  }
}

bool _supportsOperation(
  Set<String> capabilities,
  SourceRuntimeOperation operation,
) {
  if (capabilities.isEmpty) {
    return false;
  }

  return switch (operation) {
    SourceRuntimeOperation.latest => capabilities.contains(
      ExtensionsHostCapabilities.executeLatest,
    ),
    SourceRuntimeOperation.popular => capabilities.contains(
      ExtensionsHostCapabilities.executePopular,
    ),
    SourceRuntimeOperation.search => capabilities.contains(
      ExtensionsHostCapabilities.executeSearch,
    ),
  };
}
