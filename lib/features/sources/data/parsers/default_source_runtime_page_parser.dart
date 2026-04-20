import '../../../../core/bridge/extensions_host_client.dart';
import '../../domain/entities/source_manga_summary.dart';
import '../../domain/entities/source_runtime_page.dart';
import '../../domain/entities/source_runtime_request.dart';
import 'source_runtime_page_parser.dart';

/// Default parser for bridge runtime page payloads.
class DefaultSourceRuntimePageParser implements SourceRuntimePageParser {
  /// Creates the default parser.
  const DefaultSourceRuntimePageParser();

  @override
  SourceRuntimePage parse({
    required HostSourceRuntimePageResult hostPage,
    required SourceRuntimeRequest request,
  }) {
    return SourceRuntimePage(
      sourceId: hostPage.sourceId.isEmpty
          ? request.sourceId
          : hostPage.sourceId,
      items: hostPage.items
          .map(
            (HostSourceMangaPayload item) => SourceMangaSummary(
              id: item.id,
              sourceId: item.sourceId.isEmpty
                  ? request.sourceId
                  : item.sourceId,
              title: item.title,
              thumbnailUrl: item.thumbnailUrl,
              subtitle: item.subtitle,
            ),
          )
          .toList(growable: false),
      hasMore: hostPage.hasMore,
      nextPage: hostPage.nextPage,
      nextPageToken: hostPage.nextPageToken,
    );
  }
}
