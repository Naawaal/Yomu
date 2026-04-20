import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/bridge/extensions_host_client.dart';
import 'package:yomu/core/failure.dart';
import 'package:yomu/features/sources/data/datasources/source_runtime_bridge_datasource.dart';
import 'package:yomu/features/sources/data/parsers/source_runtime_page_parser.dart';
import 'package:yomu/features/sources/domain/entities/source_manga_summary.dart';
import 'package:yomu/features/sources/domain/entities/source_runtime_page.dart';
import 'package:yomu/features/sources/domain/entities/source_runtime_request.dart';

class _FakeExtensionsHostClient implements ExtensionsHostClient {
  _FakeExtensionsHostClient({
    required this.runtimeInfo,
    this.latestResult = const HostSourceRuntimePageResult(
      sourceId: 'host.latest',
      items: <HostSourceMangaPayload>[],
      hasMore: false,
    ),
    this.runtimeInfoError,
    this.latestError,
  });

  final ExtensionsHostRuntimeInfo runtimeInfo;
  final HostSourceRuntimePageResult latestResult;
  final Object? runtimeInfoError;
  final Object? latestError;

  int latestCalls = 0;
  int popularCalls = 0;
  int searchCalls = 0;

  String? lastSourceId;
  int? lastPage;
  int? lastPageSize;
  String? lastQuery;

  @override
  Future<ExtensionsHostRuntimeInfo> getRuntimeInfo() async {
    if (runtimeInfoError != null) {
      throw runtimeInfoError!;
    }
    return runtimeInfo;
  }

  @override
  Future<HostSourceRuntimePageResult> executeLatest({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) async {
    latestCalls += 1;
    lastSourceId = sourceId;
    lastPage = page;
    lastPageSize = pageSize;
    if (latestError != null) {
      throw latestError!;
    }
    return latestResult;
  }

  @override
  Future<HostSourceRuntimePageResult> executePopular({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) async {
    popularCalls += 1;
    lastSourceId = sourceId;
    lastPage = page;
    lastPageSize = pageSize;
    return latestResult;
  }

  @override
  Future<HostSourceRuntimePageResult> executeSearch({
    required String sourceId,
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    searchCalls += 1;
    lastSourceId = sourceId;
    lastQuery = query;
    lastPage = page;
    lastPageSize = pageSize;
    return latestResult;
  }

  @override
  Future<List<HostExtensionPayload>> listAvailableExtensions() async {
    throw UnimplementedError();
  }

  @override
  Future<void> trustExtension(String packageName) async {
    throw UnimplementedError();
  }

  @override
  Future<HostInstallResult> installExtension(
    String packageName, {
    String? installArtifact,
  }) async {
    throw UnimplementedError();
  }
}

class _SpySourceRuntimePageParser implements SourceRuntimePageParser {
  _SpySourceRuntimePageParser(this.result);

  final SourceRuntimePage result;
  int callCount = 0;
  HostSourceRuntimePageResult? lastHostPage;
  SourceRuntimeRequest? lastRequest;

  @override
  SourceRuntimePage parse({
    required HostSourceRuntimePageResult hostPage,
    required SourceRuntimeRequest request,
  }) {
    callCount += 1;
    lastHostPage = hostPage;
    lastRequest = request;
    return result;
  }
}

void main() {
  group('MethodChannelSourceRuntimeBridgeDataSource.execute', () {
    const ExtensionsHostRuntimeInfo runtimeInfoAllCapabilities =
        ExtensionsHostRuntimeInfo(
          schemaVersion: 1,
          capabilities: <String>{
            ExtensionsHostCapabilities.executeLatest,
            ExtensionsHostCapabilities.executePopular,
            ExtensionsHostCapabilities.executeSearch,
          },
        );

    test(
      'dispatches latest operation and delegates conversion to parser',
      () async {
        const SourceRuntimeRequest request = SourceRuntimeRequest(
          sourceId: 'source.latest',
          operation: SourceRuntimeOperation.latest,
          page: 2,
          pageSize: 24,
        );
        const HostSourceRuntimePageResult hostPage =
            HostSourceRuntimePageResult(
              sourceId: 'host.latest',
              items: <HostSourceMangaPayload>[
                HostSourceMangaPayload(
                  id: 'm1',
                  sourceId: 'host.latest',
                  title: 'A',
                ),
              ],
              hasMore: true,
              nextPage: 3,
            );
        final SourceRuntimePage parsedPage = SourceRuntimePage(
          sourceId: 'parsed.latest',
          items: const <SourceMangaSummary>[
            SourceMangaSummary(id: 'm1', sourceId: 'parsed.latest', title: 'A'),
          ],
          hasMore: true,
          nextPage: 3,
        );

        final _FakeExtensionsHostClient hostClient = _FakeExtensionsHostClient(
          runtimeInfo: runtimeInfoAllCapabilities,
          latestResult: hostPage,
        );
        final _SpySourceRuntimePageParser parser = _SpySourceRuntimePageParser(
          parsedPage,
        );
        final MethodChannelSourceRuntimeBridgeDataSource dataSource =
            MethodChannelSourceRuntimeBridgeDataSource(
              hostClient: hostClient,
              pageParser: parser,
            );

        final SourceRuntimePage result = await dataSource.execute(request);

        expect(result, parsedPage);
        expect(hostClient.latestCalls, 1);
        expect(hostClient.popularCalls, 0);
        expect(hostClient.searchCalls, 0);
        expect(hostClient.lastSourceId, 'source.latest');
        expect(hostClient.lastPage, 2);
        expect(hostClient.lastPageSize, 24);
        expect(parser.callCount, 1);
        expect(parser.lastRequest, request);
        expect(parser.lastHostPage, hostPage);
      },
    );

    test(
      'dispatches popular and search operations to matching host calls',
      () async {
        final _FakeExtensionsHostClient hostClient = _FakeExtensionsHostClient(
          runtimeInfo: runtimeInfoAllCapabilities,
        );
        final _SpySourceRuntimePageParser parser = _SpySourceRuntimePageParser(
          SourceRuntimePage(sourceId: 'parsed'),
        );
        final MethodChannelSourceRuntimeBridgeDataSource dataSource =
            MethodChannelSourceRuntimeBridgeDataSource(
              hostClient: hostClient,
              pageParser: parser,
            );

        await dataSource.execute(
          const SourceRuntimeRequest(
            sourceId: 'source.popular',
            operation: SourceRuntimeOperation.popular,
          ),
        );

        await dataSource.execute(
          const SourceRuntimeRequest(
            sourceId: 'source.search',
            operation: SourceRuntimeOperation.search,
            query: 'query',
          ),
        );

        expect(hostClient.latestCalls, 0);
        expect(hostClient.popularCalls, 1);
        expect(hostClient.searchCalls, 1);
        expect(hostClient.lastSourceId, 'source.search');
        expect(hostClient.lastQuery, 'query');
        expect(parser.callCount, 2);
      },
    );

    test(
      'throws unsupported capability before bridge call when operation is unavailable',
      () async {
        const ExtensionsHostRuntimeInfo runtimeInfoLatestOnly =
            ExtensionsHostRuntimeInfo(
              schemaVersion: 1,
              capabilities: <String>{ExtensionsHostCapabilities.executeLatest},
            );

        final _FakeExtensionsHostClient hostClient = _FakeExtensionsHostClient(
          runtimeInfo: runtimeInfoLatestOnly,
        );
        final _SpySourceRuntimePageParser parser = _SpySourceRuntimePageParser(
          SourceRuntimePage(sourceId: 'ignored'),
        );
        final MethodChannelSourceRuntimeBridgeDataSource dataSource =
            MethodChannelSourceRuntimeBridgeDataSource(
              hostClient: hostClient,
              pageParser: parser,
            );

        await expectLater(
          dataSource.execute(
            const SourceRuntimeRequest(
              sourceId: 'source.popular',
              operation: SourceRuntimeOperation.popular,
            ),
          ),
          throwsA(
            isA<SourceRuntimeBridgeException>().having(
              (SourceRuntimeBridgeException error) => error.code,
              'code',
              SourceFailureCode.unsupportedCapability,
            ),
          ),
        );

        expect(hostClient.latestCalls, 0);
        expect(hostClient.popularCalls, 0);
        expect(hostClient.searchCalls, 0);
        expect(parser.callCount, 0);
      },
    );

    test('maps MissingPluginException into typed bridge exception', () async {
      final _FakeExtensionsHostClient hostClient = _FakeExtensionsHostClient(
        runtimeInfo: runtimeInfoAllCapabilities,
        runtimeInfoError: MissingPluginException(),
      );
      final MethodChannelSourceRuntimeBridgeDataSource dataSource =
          MethodChannelSourceRuntimeBridgeDataSource(hostClient: hostClient);

      await expectLater(
        dataSource.execute(
          const SourceRuntimeRequest(
            sourceId: 'source.latest',
            operation: SourceRuntimeOperation.latest,
          ),
        ),
        throwsA(
          isA<SourceRuntimeBridgeException>()
              .having(
                (SourceRuntimeBridgeException error) => error.code,
                'code',
                SourceFailureCode.missingPlugin,
              )
              .having(
                (SourceRuntimeBridgeException error) => error.message,
                'message',
                'Source runtime bridge is unavailable on this platform.',
              ),
        ),
      );
    });

    test('maps PlatformException into typed bridge exception', () async {
      final _FakeExtensionsHostClient hostClient = _FakeExtensionsHostClient(
        runtimeInfo: runtimeInfoAllCapabilities,
        latestError: PlatformException(code: 'HOST_FAIL', message: 'boom'),
      );
      final MethodChannelSourceRuntimeBridgeDataSource dataSource =
          MethodChannelSourceRuntimeBridgeDataSource(hostClient: hostClient);

      await expectLater(
        dataSource.execute(
          const SourceRuntimeRequest(
            sourceId: 'source.latest',
            operation: SourceRuntimeOperation.latest,
          ),
        ),
        throwsA(
          isA<SourceRuntimeBridgeException>()
              .having(
                (SourceRuntimeBridgeException error) => error.code,
                'code',
                'HOST_FAIL',
              )
              .having(
                (SourceRuntimeBridgeException error) => error.message,
                'message',
                'boom',
              ),
        ),
      );
    });
  });
}
