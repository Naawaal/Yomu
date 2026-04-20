import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../../../feed/data/models/feed_item_model.dart';
import '../../../extensions/domain/entities/extension_item.dart';
import '../../../extensions/domain/repositories/extension_repository.dart';
import '../../../sources/domain/entities/source_runtime_page.dart';
import '../../../sources/domain/usecases/get_latest_source_updates_usecase.dart';
import '../models/home_feed_page_model.dart';
import '../models/home_feed_query_model.dart';

/// Abstracts remote Home feed data operations.
abstract class HomeFeedRemoteDataSource {
  /// Fetches one Home feed page using the provided query.
  Future<HomeFeedPageModel> getHomeFeedPage(HomeFeedQueryModel query);

  /// Refreshes Home feed and returns first-page results.
  Future<HomeFeedPageModel> refreshHomeFeed(HomeFeedQueryModel query);
}

/// Datasource wrapper that scopes Home feed queries to installed sources only.
class InstalledSourcesHomeFeedRemoteDataSource
    implements HomeFeedRemoteDataSource {
  InstalledSourcesHomeFeedRemoteDataSource({
    required ExtensionRepository extensionRepository,
    GetLatestSourceUpdatesUseCase? getLatestSourceUpdatesUseCase,
    bool enableRuntimeLatestFeed = true,
  }) : _extensionRepository = extensionRepository,
       _getLatestSourceUpdatesUseCase = getLatestSourceUpdatesUseCase,
       _enableRuntimeLatestFeed = enableRuntimeLatestFeed;

  final ExtensionRepository _extensionRepository;
  final GetLatestSourceUpdatesUseCase? _getLatestSourceUpdatesUseCase;
  final bool _enableRuntimeLatestFeed;

  @override
  Future<HomeFeedPageModel> getHomeFeedPage(HomeFeedQueryModel query) async {
    return _resolvePage(query);
  }

  @override
  Future<HomeFeedPageModel> refreshHomeFeed(HomeFeedQueryModel query) async {
    final HomeFeedQueryModel firstPageQuery = HomeFeedQueryModel(
      query: query.query,
      sourceIds: query.sourceIds,
      includeRead: query.includeRead,
      chronologicalGlobal: query.chronologicalGlobal,
      page: 1,
      pageSize: query.pageSize,
    );

    return _resolvePage(firstPageQuery);
  }

  Future<HomeFeedPageModel> _resolvePage(HomeFeedQueryModel query) async {
    final List<ExtensionItem> installedSources =
        await _resolveInstalledSources();
    if (installedSources.isEmpty) {
      return _emptyPage();
    }

    final List<ExtensionItem> scopedSources = _scopeInstalledSources(
      query: query,
      installedSources: installedSources,
    );
    if (scopedSources.isEmpty) {
      return _emptyPage();
    }

    final int safePage = query.page < 1 ? 1 : query.page;
    final int safePageSize = query.pageSize < 1 ? 20 : query.pageSize;

    final HomeFeedPageModel? runtimePage = await _resolveRuntimeLatestPage(
      query: query,
      scopedSources: scopedSources,
      page: safePage,
      pageSize: safePageSize,
    );
    if (runtimePage != null) {
      return runtimePage;
    }

    final int start = (safePage - 1) * safePageSize;

    if (start >= scopedSources.length) {
      return _emptyPage();
    }

    final int end = (start + safePageSize).clamp(0, scopedSources.length);
    final bool hasMore = end < scopedSources.length;
    final List<FeedItemModel> pageItems = scopedSources
        .sublist(start, end)
        .map((ExtensionItem source) {
          return FeedItemModel(
            id: 'home-source-${source.packageName}',
            sourceId: source.packageName,
            title: source.name,
            subtitle: 'Latest updates from ${source.name}',
            imageUrl: source.iconUrl ?? '',
            metadata:
                '${source.language.toUpperCase()} • v${source.versionName}',
            isBookmarked: false,
          );
        })
        .toList(growable: false);

    return HomeFeedPageModel(
      items: pageItems,
      hasMore: hasMore,
      nextPage: hasMore ? safePage + 1 : null,
      nextPageToken: hasMore ? 'page-${safePage + 1}' : null,
    );
  }

  Future<HomeFeedPageModel?> _resolveRuntimeLatestPage({
    required HomeFeedQueryModel query,
    required List<ExtensionItem> scopedSources,
    required int page,
    required int pageSize,
  }) async {
    if (!_enableRuntimeLatestFeed || _getLatestSourceUpdatesUseCase == null) {
      return null;
    }
    if (scopedSources.isEmpty) {
      return _emptyPage();
    }

    final String normalizedQuery = query.query.trim().toLowerCase();
    final List<FeedItemModel> mapped = <FeedItemModel>[];
    bool hasMore = false;
    int? nextPage;
    String? nextPageToken;

    for (final ExtensionItem source in scopedSources) {
      final Either<Failure, SourceRuntimePage> runtimeResult =
          await _getLatestSourceUpdatesUseCase(
            sourceId: source.packageName,
            page: page,
            pageSize: pageSize,
          );

      runtimeResult.fold((_) {}, (SourceRuntimePage runtimePage) {
        if (runtimePage.hasMore) {
          hasMore = true;
        }
        nextPage ??= runtimePage.nextPage;
        nextPageToken ??= runtimePage.nextPageToken;

        mapped.addAll(
          runtimePage.items
              .where((item) {
                if (normalizedQuery.isEmpty) {
                  return true;
                }

                final String subtitle = item.subtitle?.toLowerCase() ?? '';
                return item.title.toLowerCase().contains(normalizedQuery) ||
                    subtitle.contains(normalizedQuery);
              })
              .map((item) {
                return FeedItemModel(
                  id: 'runtime-${source.packageName}-${item.id}',
                  sourceId: item.sourceId,
                  title: item.title,
                  subtitle:
                      item.subtitle ?? 'Latest updates from ${source.name}',
                  imageUrl: item.thumbnailUrl ?? source.iconUrl ?? '',
                  metadata: '${source.language.toUpperCase()} • ${source.name}',
                  isBookmarked: false,
                );
              }),
        );
      });
    }

    if (mapped.isEmpty) {
      // Runtime path can be temporarily empty/failing while native execution is
      // being rolled out. Keep legacy source-row fallback until runtime returns
      // real content for at least one scoped source.
      return null;
    }

    return HomeFeedPageModel(
      items: List<FeedItemModel>.unmodifiable(mapped),
      hasMore: hasMore,
      nextPage: nextPage,
      nextPageToken: nextPageToken,
    );
  }

  Future<List<ExtensionItem>> _resolveInstalledSources() async {
    final items = await _extensionRepository.getAvailableExtensions();
    return items.where((item) => item.isInstalled).toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
  }

  List<ExtensionItem> _scopeInstalledSources({
    required HomeFeedQueryModel query,
    required List<ExtensionItem> installedSources,
  }) {
    final String normalizedQuery = query.query.trim().toLowerCase();
    final Set<String> sourceFilter = query.sourceIds.toSet();

    return installedSources
        .where((ExtensionItem source) {
          if (sourceFilter.isNotEmpty &&
              !sourceFilter.contains(source.packageName)) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return source.name.toLowerCase().contains(normalizedQuery) ||
              source.packageName.toLowerCase().contains(normalizedQuery) ||
              source.language.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  HomeFeedPageModel _emptyPage() {
    return HomeFeedPageModel(
      items: const <FeedItemModel>[],
      hasMore: false,
      nextPage: null,
      nextPageToken: null,
    );
  }
}

/// In-memory mock implementation for Home feed datasource.
class MockHomeFeedRemoteDataSource implements HomeFeedRemoteDataSource {
  MockHomeFeedRemoteDataSource()
    : _items = <FeedItemModel>[
        const FeedItemModel(
          id: 'home-001',
          sourceId: 'eu.kanade.tachiyomi.extension.en.mangadex',
          title: 'Sakamoto Days',
          subtitle: 'Chapter 210 is out now',
          imageUrl: '',
          metadata: 'MangaDex • 15m ago',
          isBookmarked: false,
        ),
        const FeedItemModel(
          id: 'home-002',
          sourceId: 'eu.kanade.tachiyomi.extension.en.mangasee',
          title: 'Dandadan',
          subtitle: 'New chapter translated',
          imageUrl: '',
          metadata: 'MangaSee • 1h ago',
          isBookmarked: true,
        ),
        const FeedItemModel(
          id: 'home-003',
          sourceId: 'eu.kanade.tachiyomi.extension.en.nekoscans',
          title: 'Kagurabachi',
          subtitle: 'Weekly release synced',
          imageUrl: '',
          metadata: 'NekoScans • 2h ago',
          isBookmarked: false,
        ),
        const FeedItemModel(
          id: 'home-004',
          sourceId: 'eu.kanade.tachiyomi.extension.en.mangalife',
          title: 'One Piece',
          subtitle: 'Chapter 1150 raw discussion',
          imageUrl: '',
          metadata: 'MangaLife • 4h ago',
          isBookmarked: false,
        ),
      ];

  final List<FeedItemModel> _items;

  @override
  Future<HomeFeedPageModel> getHomeFeedPage(HomeFeedQueryModel query) async {
    final String normalizedQuery = query.query.trim().toLowerCase();
    final Set<String> sourceFilter = query.sourceIds.toSet();

    final List<FeedItemModel> filtered = _items
        .where((FeedItemModel item) {
          if (sourceFilter.isNotEmpty &&
              !sourceFilter.contains(item.sourceId)) {
            return false;
          }

          if (normalizedQuery.isEmpty) {
            return true;
          }
          return item.title.toLowerCase().contains(normalizedQuery) ||
              item.subtitle.toLowerCase().contains(normalizedQuery) ||
              item.metadata.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    final int safePage = query.page < 1 ? 1 : query.page;
    final int safePageSize = query.pageSize < 1 ? 20 : query.pageSize;
    final int start = (safePage - 1) * safePageSize;

    if (start >= filtered.length) {
      return HomeFeedPageModel(
        items: const <FeedItemModel>[],
        hasMore: false,
        nextPage: null,
        nextPageToken: null,
      );
    }

    final int end = (start + safePageSize).clamp(0, filtered.length);
    final bool hasMore = end < filtered.length;

    return HomeFeedPageModel(
      items: filtered.sublist(start, end),
      hasMore: hasMore,
      nextPage: hasMore ? safePage + 1 : null,
      nextPageToken: hasMore ? 'page-${safePage + 1}' : null,
    );
  }

  @override
  Future<HomeFeedPageModel> refreshHomeFeed(HomeFeedQueryModel query) {
    final HomeFeedQueryModel firstPageQuery = HomeFeedQueryModel(
      query: query.query,
      sourceIds: query.sourceIds,
      includeRead: query.includeRead,
      chronologicalGlobal: query.chronologicalGlobal,
      page: 1,
      pageSize: query.pageSize,
    );

    return getHomeFeedPage(firstPageQuery);
  }
}
