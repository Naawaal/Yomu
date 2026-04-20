import '../../../../core/bridge/extensions_host_client.dart';
import '../../domain/entities/source_runtime_page.dart';
import '../../domain/entities/source_runtime_request.dart';

/// Parses host runtime payloads into source runtime pages.
abstract class SourceRuntimePageParser {
  /// Maps a host result into a [SourceRuntimePage] for the given request.
  SourceRuntimePage parse({
    required HostSourceRuntimePageResult hostPage,
    required SourceRuntimeRequest request,
  });
}
