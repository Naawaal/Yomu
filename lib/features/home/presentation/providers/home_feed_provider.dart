import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bridge/extensions_host_client.dart';
import '../../../../core/failure.dart';
import '../../../extensions/domain/entities/extension_item.dart';
import '../../../extensions/domain/repositories/extension_repository.dart';
import '../../../extensions/presentation/controllers/extensions_controllers.dart';
import '../../../sources/data/datasources/source_runtime_bridge_datasource.dart';
import '../../../sources/data/repositories/source_catalog_repository_impl.dart';
import '../../../sources/data/repositories/source_runtime_repository_impl.dart';
import '../../../sources/domain/entities/source_runtime_page.dart';
import '../../../sources/domain/repositories/i_source_catalog_repository.dart';
import '../../../sources/domain/repositories/i_source_runtime_repository.dart';
import '../../../sources/domain/usecases/get_latest_source_updates_usecase.dart';
import '../../../sources/domain/usecases/search_source_catalog_usecase.dart';
import '../../data/datasources/home_feed_remote_datasource.dart';
import '../../data/repositories/home_feed_repository_impl.dart';
import '../../../feed/domain/entities/feed_item.dart';
import '../../domain/entities/home_feed_page.dart';
import '../../domain/entities/home_feed_query.dart';
import '../../domain/repositories/i_home_feed_repository.dart';
import '../../domain/usecases/get_home_feed_page_usecase.dart';
import '../../domain/usecases/refresh_home_feed_usecase.dart';

/// Source-filtering mode applied to Home feed source selection.
enum HomeSourceFilterMode {
  /// Combined feed from all installed sources.
  all,

  /// Feed includes only explicitly selected sources.
  include,

  /// Feed excludes explicitly selected sources.
  exclude,
}

/// Enables runtime-backed Home latest feed integration for smoke validation.
const bool _enableRuntimeLatestHomeFeed = bool.fromEnvironment(
  'YOMU_ENABLE_RUNTIME_LATEST_HOME_FEED',
  defaultValue: true,
);

/// Provides source runtime bridge datasource implementation.
final sourceRuntimeBridgeDataSourceProvider =
    Provider<SourceRuntimeBridgeDataSource>((Ref ref) {
      return MethodChannelSourceRuntimeBridgeDataSource(
        hostClient: MethodChannelExtensionsHostClient(),
      );
    });

/// Provides source runtime repository implementation.
final sourceRuntimeRepositoryProvider = Provider<ISourceRuntimeRepository>((
  Ref ref,
) {
  return SourceRuntimeRepositoryImpl(
    ref.watch(sourceRuntimeBridgeDataSourceProvider),
  );
});

/// Provides composed source catalog repository implementation.
final sourceCatalogRepositoryProvider = Provider<ISourceCatalogRepository>((
  Ref ref,
) {
  return SourceCatalogRepositoryImpl(
    extensionRepository: ref.watch(extensionRepositoryProvider),
    runtimeRepository: ref.watch(sourceRuntimeRepositoryProvider),
  );
});

/// Provides latest-updates runtime use case for source execution.
final getLatestSourceUpdatesUseCaseProvider =
    Provider<GetLatestSourceUpdatesUseCase>((Ref ref) {
      return GetLatestSourceUpdatesUseCase(
        ref.watch(sourceCatalogRepositoryProvider),
      );
    });

/// Provides source-catalog search use case for runtime feed queries.
final searchSourceCatalogUseCaseProvider = Provider<SearchSourceCatalogUseCase>(
  (Ref ref) {
    return SearchSourceCatalogUseCase(
      ref.watch(sourceCatalogRepositoryProvider),
    );
  },
);

/// Provides the Home feed remote datasource implementation.
final homeFeedRemoteDataSourceProvider = Provider<HomeFeedRemoteDataSource>((
  Ref ref,
) {
  return InstalledSourcesHomeFeedRemoteDataSource(
    extensionRepository: ref.watch(extensionRepositoryProvider),
    getLatestSourceUpdatesUseCase: ref.watch(
      getLatestSourceUpdatesUseCaseProvider,
    ),
    enableRuntimeLatestFeed: _enableRuntimeLatestHomeFeed,
  );
});

/// Provides the Home feed repository implementation.
final homeFeedRepositoryProvider = Provider<IHomeFeedRepository>((Ref ref) {
  return HomeFeedRepositoryImpl(ref.watch(homeFeedRemoteDataSourceProvider));
});

/// Provides the Home feed page retrieval use case.
final getHomeFeedPageUseCaseProvider = Provider<GetHomeFeedPageUseCase>((
  Ref ref,
) {
  return GetHomeFeedPageUseCase(ref.watch(homeFeedRepositoryProvider));
});

/// Provides the Home feed refresh use case.
final refreshHomeFeedUseCaseProvider = Provider<RefreshHomeFeedUseCase>((
  Ref ref,
) {
  return RefreshHomeFeedUseCase(ref.watch(homeFeedRepositoryProvider));
});

/// State notifier for tracking user-selected source IDs for feed filtering.
class SelectedSourceIdsNotifier extends StateNotifier<Set<String>> {
  SelectedSourceIdsNotifier() : super(const <String>{});

  /// Updates selected source IDs.
  void updateSelectedSources(Set<String> newSelection) {
    state = newSelection;
  }

  /// Toggles a source on/off in the selection set.
  void toggleSource(String sourceId) {
    if (state.contains(sourceId)) {
      state = state.where((id) => id != sourceId).toSet();
    } else {
      state = <String>{...state, sourceId};
    }
  }

  /// Clears all selected sources.
  void clearSelection() {
    state = const <String>{};
  }

  /// Selects all provided source IDs.
  void selectAll(List<String> sourceIds) {
    state = sourceIds.toSet();
  }
}

/// Provides the selected source IDs state notifier.
final selectedSourceIdsProvider =
    StateNotifierProvider<SelectedSourceIdsNotifier, Set<String>>(
      (_) => SelectedSourceIdsNotifier(),
    );

/// State notifier for source filter mode (all/include/exclude).
class HomeSourceFilterModeNotifier extends StateNotifier<HomeSourceFilterMode> {
  HomeSourceFilterModeNotifier() : super(HomeSourceFilterMode.include);

  /// Sets filter mode to combine all installed sources.
  void setAll() => state = HomeSourceFilterMode.all;

  /// Sets filter mode to include-only behavior.
  void setInclude() => state = HomeSourceFilterMode.include;

  /// Sets filter mode to exclude behavior.
  void setExclude() => state = HomeSourceFilterMode.exclude;

  /// Updates filter mode explicitly.
  void updateMode(HomeSourceFilterMode mode) => state = mode;
}

/// Provides selected source filter mode for Home feed resolution.
final homeSourceFilterModeProvider =
    StateNotifierProvider<HomeSourceFilterModeNotifier, HomeSourceFilterMode>(
      (_) => HomeSourceFilterModeNotifier(),
    );

/// Async notifier for Home feed loading, refresh, and pagination flows.
class HomeFeedNotifier extends AsyncNotifier<HomeFeedPage> {
  HomeFeedQuery _query = HomeFeedQuery.initial;
  List<String> _installedSourceIds = const <String>[];
  Set<String> _lastWatchedSources = const <String>{};
  HomeSourceFilterMode _lastWatchedFilterMode = HomeSourceFilterMode.include;

  /// Latest installed source IDs discovered from extensions.
  List<String> get installedSourceIds =>
      List<String>.unmodifiable(_installedSourceIds);

  /// Whether multiple installed sources are available for include/exclude UI.
  bool get hasMultipleInstalledSources => _installedSourceIds.length > 1;

  @override
  Future<HomeFeedPage> build() async {
    // Watch selected sources to detect changes and auto-refresh feed.
    final Set<String> currentSelectedSources = ref.watch(
      selectedSourceIdsProvider,
    );
    final HomeSourceFilterMode currentFilterMode = ref.watch(
      homeSourceFilterModeProvider,
    );

    // If sources changed and we have a previous state, refresh to page 1.
    if ((_lastWatchedSources != currentSelectedSources ||
            _lastWatchedFilterMode != currentFilterMode) &&
        state.hasValue) {
      _lastWatchedSources = currentSelectedSources;
      _lastWatchedFilterMode = currentFilterMode;
      _query = _query.copyWith(page: 1);
      return await _performRefresh();
    }

    _lastWatchedSources = currentSelectedSources;
    _lastWatchedFilterMode = currentFilterMode;
    return HomeFeedPage.empty;
  }

  /// Helper to perform refresh without modifying _lastWatchedSources again.
  Future<HomeFeedPage> _performRefresh() async {
    final List<String> installedSourceIds = await _resolveInstalledSourceIds();
    _installedSourceIds = installedSourceIds;

    final List<String> sourcesForQuery = _resolveSourcesToUse(
      installedSourceIds: installedSourceIds,
      userSelectedSources: _lastWatchedSources,
      filterMode: _lastWatchedFilterMode,
    );

    _query = _resolveQueryByInstalledSources(
      query: _query,
      installedSourceIds: installedSourceIds,
      overrideSources: sourcesForQuery,
    );

    final RefreshHomeFeedUseCase useCase = ref.read(
      refreshHomeFeedUseCaseProvider,
    );
    final result = await useCase(_query.copyWith(page: 1));

    return result.fold((failure) => throw StateError(failure.message), (page) {
      _query = _query.copyWith(page: page.nextPage ?? 1);
      return page;
    });
  }

  /// Loads Home feed for the provided query.
  Future<void> fetch({HomeFeedQuery? query}) async {
    final HomeFeedQuery baseQuery = query ?? _query;
    final List<String> installedSourceIds = await _resolveInstalledSourceIds();
    _installedSourceIds = installedSourceIds;

    // Watch user-selected sources to determine feed query
    final Set<String> userSelectedSources = ref.watch(
      selectedSourceIdsProvider,
    );
    final HomeSourceFilterMode filterMode = ref.watch(
      homeSourceFilterModeProvider,
    );
    _lastWatchedFilterMode = filterMode;
    final List<String> sourcesForQuery = _resolveSourcesToUse(
      installedSourceIds: installedSourceIds,
      userSelectedSources: userSelectedSources,
      filterMode: filterMode,
    );

    _query = _resolveQueryByInstalledSources(
      query: baseQuery,
      installedSourceIds: installedSourceIds,
      overrideSources: sourcesForQuery,
    );

    state = const AsyncLoading<HomeFeedPage>();

    final HomeFeedPage? runtimePage = await _tryResolveRuntimePage(_query);
    if (runtimePage != null) {
      _query = _query.copyWith(page: runtimePage.nextPage ?? _query.page);
      state = AsyncData<HomeFeedPage>(runtimePage);
      return;
    }

    final GetHomeFeedPageUseCase useCase = ref.read(
      getHomeFeedPageUseCaseProvider,
    );
    final result = await useCase(_query);

    state = result.fold(
      (failure) => AsyncError<HomeFeedPage>(
        StateError(failure.message),
        StackTrace.current,
      ),
      AsyncData<HomeFeedPage>.new,
    );
  }

  /// Refreshes Home feed and resets to first page.
  Future<void> refresh() async {
    final List<String> installedSourceIds = await _resolveInstalledSourceIds();
    _installedSourceIds = installedSourceIds;

    // Watch user-selected sources to determine feed query
    final Set<String> userSelectedSources = ref.watch(
      selectedSourceIdsProvider,
    );
    final HomeSourceFilterMode filterMode = ref.watch(
      homeSourceFilterModeProvider,
    );
    _lastWatchedFilterMode = filterMode;
    final List<String> sourcesForQuery = _resolveSourcesToUse(
      installedSourceIds: installedSourceIds,
      userSelectedSources: userSelectedSources,
      filterMode: filterMode,
    );

    _query = _resolveQueryByInstalledSources(
      query: _query,
      installedSourceIds: installedSourceIds,
      overrideSources: sourcesForQuery,
    );

    final HomeFeedPage refreshQueryPage =
        await _tryResolveRuntimePage(_query.copyWith(page: 1)) ??
        HomeFeedPage.empty;
    if (refreshQueryPage.items.isNotEmpty ||
        (refreshQueryPage.nextPage != null || refreshQueryPage.hasMore)) {
      _query = _query.copyWith(page: refreshQueryPage.nextPage ?? 1);
      state = AsyncData<HomeFeedPage>(refreshQueryPage);
      return;
    }

    final RefreshHomeFeedUseCase useCase = ref.read(
      refreshHomeFeedUseCaseProvider,
    );
    final result = await useCase(_query.copyWith(page: 1));

    state = result.fold(
      (failure) => AsyncError<HomeFeedPage>(
        StateError(failure.message),
        StackTrace.current,
      ),
      (HomeFeedPage page) {
        _query = _query.copyWith(page: page.nextPage ?? 1);
        return AsyncData<HomeFeedPage>(page);
      },
    );
  }

  /// Loads the next page and appends it to the current state.
  Future<void> loadMore() async {
    final HomeFeedPage currentPage = state.valueOrNull ?? HomeFeedPage.empty;
    if (!currentPage.hasMore) {
      return;
    }

    final int nextPage = currentPage.nextPage ?? _query.page;

    final HomeFeedPage? runtimePage = await _tryResolveRuntimePage(
      _query.copyWith(page: nextPage),
    );
    if (runtimePage != null) {
      _query = _query.copyWith(page: runtimePage.nextPage ?? nextPage);
      state = AsyncData<HomeFeedPage>(
        HomeFeedPage(
          items: <FeedItem>[...currentPage.items, ...runtimePage.items],
          hasMore: runtimePage.hasMore,
          nextPage: runtimePage.nextPage,
          nextPageToken: runtimePage.nextPageToken,
        ),
      );
      return;
    }

    final GetHomeFeedPageUseCase useCase = ref.read(
      getHomeFeedPageUseCaseProvider,
    );
    final result = await useCase(_query.copyWith(page: nextPage));

    state = result.fold(
      (failure) => AsyncError<HomeFeedPage>(
        StateError(failure.message),
        StackTrace.current,
      ),
      (HomeFeedPage incoming) {
        _query = _query.copyWith(page: incoming.nextPage ?? nextPage);
        return AsyncData<HomeFeedPage>(
          HomeFeedPage(
            items: <FeedItem>[...currentPage.items, ...incoming.items],
            hasMore: incoming.hasMore,
            nextPage: incoming.nextPage,
            nextPageToken: incoming.nextPageToken,
          ),
        );
      },
    );
  }

  Future<List<String>> _resolveInstalledSourceIds() async {
    final extensionRepository = ref.read(extensionRepositoryProvider);
    final items = await extensionRepository.getAvailableExtensions();
    return items
        .where((item) => item.isInstalled)
        .map((item) => item.packageName)
        .toSet()
        .toList(growable: false);
  }

  Future<HomeFeedPage?> _tryResolveRuntimePage(HomeFeedQuery query) async {
    if (!_enableRuntimeLatestHomeFeed) {
      return null;
    }

    final List<String> sourceIds = query.sourceIds;
    if (sourceIds.isEmpty) {
      return null;
    }

    final ExtensionRepository extensionRepository = ref.read(
      extensionRepositoryProvider,
    );
    final List<ExtensionItem> extensionItems = await extensionRepository
        .getAvailableExtensions();
    final Map<String, ExtensionItem> sourceMetadata = <String, ExtensionItem>{
      for (final ExtensionItem item in extensionItems)
        if (item.isInstalled) item.packageName: item,
    };

    final GetLatestSourceUpdatesUseCase latestUseCase = ref.read(
      getLatestSourceUpdatesUseCaseProvider,
    );
    final SearchSourceCatalogUseCase searchUseCase = ref.read(
      searchSourceCatalogUseCaseProvider,
    );

    final bool useSearch = query.query.trim().isNotEmpty;
    final List<FeedItem> feedItems = <FeedItem>[];
    bool hasMore = false;
    int? nextPage;
    String? nextPageToken;

    for (final String sourceId in sourceIds) {
      final Either<Failure, SourceRuntimePage> result = useSearch
          ? await searchUseCase(
              sourceId: sourceId,
              query: query.query,
              page: query.page,
              pageSize: query.pageSize,
            )
          : await latestUseCase(
              sourceId: sourceId,
              page: query.page,
              pageSize: query.pageSize,
            );

      result.fold((_) {}, (SourceRuntimePage page) {
        if (page.hasMore) {
          hasMore = true;
        }
        nextPage ??= page.nextPage;
        nextPageToken ??= page.nextPageToken;

        final ExtensionItem? metadata = sourceMetadata[sourceId];
        feedItems.addAll(
          page.items.map((item) {
            return FeedItem(
              id: 'runtime-$sourceId-${item.id}',
              sourceId: item.sourceId,
              title: item.title,
              subtitle:
                  item.subtitle ??
                  'Latest updates from ${metadata?.name ?? sourceId}',
              imageUrl: item.thumbnailUrl ?? metadata?.iconUrl ?? '',
              metadata:
                  '${(metadata?.language ?? 'all').toUpperCase()} • '
                  '${metadata?.name ?? sourceId}',
              isBookmarked: false,
            );
          }),
        );
      });
    }

    if (feedItems.isEmpty) {
      return null;
    }

    return HomeFeedPage(
      items: feedItems,
      hasMore: hasMore,
      nextPage: nextPage,
      nextPageToken: nextPageToken,
    );
  }

  /// Determines which source IDs should be used in the feed query.
  ///
  /// Priority:
  /// 1. If user has explicitly selected sources, use those (if valid against installed)
  /// 2. Otherwise, use default resolution logic (auto-select single, include all multiple)
  List<String> _resolveSourcesToUse({
    required List<String> installedSourceIds,
    required Set<String> userSelectedSources,
    required HomeSourceFilterMode filterMode,
  }) {
    final Set<String> installedSet = installedSourceIds.toSet();
    final List<String> validSelected = userSelectedSources
        .where(installedSet.contains)
        .toList(growable: false);

    if (filterMode == HomeSourceFilterMode.all) {
      return installedSourceIds;
    }

    if (filterMode == HomeSourceFilterMode.exclude) {
      if (validSelected.isEmpty) {
        return installedSourceIds;
      }

      return installedSourceIds
          .where((String sourceId) => !userSelectedSources.contains(sourceId))
          .toList(growable: false);
    }

    if (validSelected.isNotEmpty) {
      return validSelected;
    }

    return installedSourceIds;
  }

  HomeFeedQuery _resolveQueryByInstalledSources({
    required HomeFeedQuery query,
    required List<String> installedSourceIds,
    List<String>? overrideSources,
  }) {
    final List<String> sourcesToUse = overrideSources ?? installedSourceIds;

    if (sourcesToUse.isEmpty) {
      return query.copyWith(sourceIds: const <String>[]);
    }

    final Set<String> sourceSet = sourcesToUse.toSet();
    final List<String> requestedSourceIds = query.sourceIds
        .where(sourceSet.contains)
        .toList(growable: false);

    if (requestedSourceIds.isNotEmpty) {
      return query.copyWith(sourceIds: requestedSourceIds);
    }

    if (sourcesToUse.length == 1) {
      return query.copyWith(sourceIds: <String>[sourcesToUse.first]);
    }

    return query.copyWith(sourceIds: sourcesToUse);
  }
}

/// Provides HomeFeedNotifier for presentation consumers.
final homeFeedNotifierProvider =
    AsyncNotifierProvider<HomeFeedNotifier, HomeFeedPage>(HomeFeedNotifier.new);
