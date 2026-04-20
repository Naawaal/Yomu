import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/bridge/extensions_host_client.dart';
import 'package:yomu/features/sources/data/parsers/default_source_runtime_page_parser.dart';
import 'package:yomu/features/sources/domain/entities/source_runtime_request.dart';

void main() {
  group('DefaultSourceRuntimePageParser.parse', () {
    const DefaultSourceRuntimePageParser parser =
        DefaultSourceRuntimePageParser();

    test('maps host payload fields to runtime page and summary items', () {
      const SourceRuntimeRequest request = SourceRuntimeRequest(
        sourceId: 'source.request',
        operation: SourceRuntimeOperation.latest,
        page: 2,
        pageSize: 30,
      );

      const HostSourceRuntimePageResult hostPage = HostSourceRuntimePageResult(
        sourceId: 'source.host',
        items: <HostSourceMangaPayload>[
          HostSourceMangaPayload(
            id: 'manga-1',
            sourceId: 'source.item',
            title: 'Title 1',
            subtitle: 'Sub 1',
            thumbnailUrl: 'https://img.example/1.jpg',
          ),
        ],
        hasMore: true,
        nextPage: 3,
        nextPageToken: 'cursor-3',
      );

      final page = parser.parse(hostPage: hostPage, request: request);

      expect(page.sourceId, 'source.host');
      expect(page.hasMore, isTrue);
      expect(page.nextPage, 3);
      expect(page.nextPageToken, 'cursor-3');
      expect(page.items, hasLength(1));
      expect(page.items.first.id, 'manga-1');
      expect(page.items.first.sourceId, 'source.item');
      expect(page.items.first.title, 'Title 1');
      expect(page.items.first.subtitle, 'Sub 1');
      expect(page.items.first.thumbnailUrl, 'https://img.example/1.jpg');
    });

    test('falls back to request sourceId when host sourceIds are empty', () {
      const SourceRuntimeRequest request = SourceRuntimeRequest(
        sourceId: 'source.request',
        operation: SourceRuntimeOperation.popular,
      );

      const HostSourceRuntimePageResult hostPage = HostSourceRuntimePageResult(
        sourceId: '',
        items: <HostSourceMangaPayload>[
          HostSourceMangaPayload(id: 'manga-2', sourceId: '', title: 'Title 2'),
        ],
        hasMore: false,
      );

      final page = parser.parse(hostPage: hostPage, request: request);

      expect(page.sourceId, 'source.request');
      expect(page.items, hasLength(1));
      expect(page.items.first.sourceId, 'source.request');
    });

    test('handles empty payload rows without throwing', () {
      const SourceRuntimeRequest request = SourceRuntimeRequest(
        sourceId: 'source.request',
        operation: SourceRuntimeOperation.search,
        query: 'query',
      );

      const HostSourceRuntimePageResult hostPage = HostSourceRuntimePageResult(
        sourceId: '',
        items: <HostSourceMangaPayload>[
          HostSourceMangaPayload(id: '', sourceId: '', title: ''),
        ],
        hasMore: false,
      );

      final page = parser.parse(hostPage: hostPage, request: request);

      expect(page.sourceId, 'source.request');
      expect(page.items, hasLength(1));
      expect(page.items.first.id, '');
      expect(page.items.first.sourceId, 'source.request');
      expect(page.items.first.title, '');
    });
  });
}
