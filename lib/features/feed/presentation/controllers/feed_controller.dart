import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/feed_local_datasource.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../domain/entities/feed_filter.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/repositories/i_feed_repository.dart';
import '../../domain/usecases/get_feed_items_usecase.dart';
import '../../domain/usecases/refresh_feed_usecase.dart';
import '../../../../core/failure.dart';

part 'feed_controller.g.dart';

const int _defaultPageSize = 20;

/// Presentation state for the home feed surface.
class FeedViewState {
  /// Creates a feed view state.
  const FeedViewState({
    required this.items,
    required this.filter,
    required this.page,
    required this.hasMore,
    required this.lastSyncedAt,
  });

  /// Empty baseline feed state.
  const FeedViewState.empty()
    : items = const <FeedItem>[],
      filter = FeedFilter.initial,
      page = 1,
      hasMore = true,
      lastSyncedAt = null;

  /// Loaded feed items.
  final List<FeedItem> items;

  /// Active feed filter.
  final FeedFilter filter;

  /// Current one-based page index.
  final int page;

  /// Whether another page may be requested.
  final bool hasMore;

  /// Most recent successful sync timestamp.
  final DateTime? lastSyncedAt;

  /// Returns a copy with updated values.
  FeedViewState copyWith({
    List<FeedItem>? items,
    FeedFilter? filter,
    int? page,
    bool? hasMore,
    DateTime? lastSyncedAt,
  }) {
    return FeedViewState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// Provides the feed local datasource implementation.
@riverpod
FeedLocalDataSource feedLocalDataSource(Ref ref) {
  return InMemoryFeedLocalDataSource();
}

/// Provides the feed remote datasource implementation.
@riverpod
FeedRemoteDataSource feedRemoteDataSource(Ref ref) {
  return MockFeedRemoteDataSource();
}

/// Provides the feed repository implementation.
@riverpod
FeedRepository feedRepository(Ref ref) {
  return _LegacyFeedRepositoryAdapter(ref.watch(feedRemoteDataSourceProvider));
}

/// Provides the get-feed-items use case.
@riverpod
GetFeedItemsUseCase getFeedItemsUseCase(Ref ref) {
  return GetFeedItemsUseCase(
    _LegacyToNewRepositoryAdapter(ref.watch(feedRepositoryProvider)),
  );
}

/// Provides the refresh-feed use case.
@riverpod
RefreshFeedUseCase refreshFeedUseCase(Ref ref) {
  return RefreshFeedUseCase(ref.watch(feedRepositoryProvider));
}

/// Async controller for loading, filtering, and refreshing feed state.
@riverpod
class FeedController extends _$FeedController {
  @override
  Future<FeedViewState> build() async {
    return _loadInitialState(FeedFilter.initial);
  }

  /// Reloads feed data for the current filter from the remote source.
  Future<void> refresh() async {
    final FeedViewState previous =
        state.valueOrNull ?? const FeedViewState.empty();
    final RefreshFeedUseCase useCase = ref.read(refreshFeedUseCaseProvider);

    state = const AsyncLoading<FeedViewState>();
    state = await AsyncValue.guard(() async {
      final List<FeedItem> refreshedItems = await useCase(
        RefreshFeedParams(filter: previous.filter, pageSize: _defaultPageSize),
      );
      return FeedViewState(
        items: refreshedItems,
        filter: previous.filter,
        page: 1,
        hasMore: refreshedItems.length >= _defaultPageSize,
        lastSyncedAt: DateTime.now(),
      );
    });
  }

  /// Applies a new filter and reloads feed data from page one.
  Future<void> applyFilter(FeedFilter filter) async {
    state = const AsyncLoading<FeedViewState>();
    state = await AsyncValue.guard(() async {
      return _loadInitialState(filter);
    });
  }

  /// Loads the next feed page when more results are available.
  Future<void> loadNextPage() async {
    final FeedViewState current =
        state.valueOrNull ?? const FeedViewState.empty();
    if (!current.hasMore) {
      return;
    }

    final int nextPage = current.page + 1;
    final GetFeedItemsUseCase useCase = ref.read(getFeedItemsUseCaseProvider);

    state = await AsyncValue.guard(() async {
      final Either<Failure, List<FeedItem>> result = await useCase(
        filters: _filtersToMap(current.filter),
        page: nextPage,
      );
      final List<FeedItem> nextItems = result.fold(
        (Failure _) => <FeedItem>[],
        (List<FeedItem> items) => items,
      );

      return current.copyWith(
        items: <FeedItem>[...current.items, ...nextItems],
        page: nextPage,
        hasMore: nextItems.length >= _defaultPageSize,
        lastSyncedAt: DateTime.now(),
      );
    });
  }

  Future<FeedViewState> _loadInitialState(FeedFilter filter) async {
    final GetFeedItemsUseCase useCase = ref.read(getFeedItemsUseCaseProvider);
    final Either<Failure, List<FeedItem>> result = await useCase(
      filters: _filtersToMap(filter),
      page: 1,
    );
    final List<FeedItem> items = result.fold(
      (Failure _) => <FeedItem>[],
      (List<FeedItem> value) => value,
    );

    return FeedViewState(
      items: items,
      filter: filter,
      page: 1,
      hasMore: items.length >= _defaultPageSize,
      lastSyncedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _filtersToMap(FeedFilter filter) {
    return <String, dynamic>{
      'query': filter.query,
      'includeRead': filter.includeRead,
      'sortOrder': filter.sortOrder.name,
    };
  }
}

class _LegacyFeedRepositoryAdapter implements FeedRepository {
  const _LegacyFeedRepositoryAdapter(this._remoteDataSource);

  final FeedRemoteDataSource _remoteDataSource;

  @override
  Future<List<FeedItem>> getFeedItems({
    required FeedFilter filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final List<FeedItem> items = await _remoteDataSource.fetchFeedItems(
      filters: <String, dynamic>{
        'query': filter.query,
        'includeRead': filter.includeRead,
        'sortOrder': filter.sortOrder.name,
        'pageSize': pageSize,
      },
      page: page,
    );
    return items;
  }

  @override
  Future<List<FeedItem>> refreshFeed({
    required FeedFilter filter,
    int pageSize = 20,
  }) {
    return getFeedItems(filter: filter, page: 1, pageSize: pageSize);
  }
}

class _LegacyToNewRepositoryAdapter implements IFeedRepository {
  const _LegacyToNewRepositoryAdapter(this._legacyRepository);

  final FeedRepository _legacyRepository;

  @override
  Future<Either<Failure, Unit>> bookmarkFeedItem(String id) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<FeedItem>>> fetchFeedItems({
    Map<String, dynamic>? filters,
    int? page,
  }) async {
    final FeedFilter filter = FeedFilter(
      query: filters?['query'] as String? ?? '',
      includeRead: filters?['includeRead'] as bool? ?? true,
      sortOrder:
          (filters?['sortOrder'] as String?) == FeedSortOrder.oldestFirst.name
          ? FeedSortOrder.oldestFirst
          : FeedSortOrder.newestFirst,
    );

    final List<FeedItem> items = await _legacyRepository.getFeedItems(
      filter: filter,
      page: page ?? 1,
      pageSize: _defaultPageSize,
    );
    return Right(items);
  }

  @override
  Future<Either<Failure, Unit>> unbookmarkFeedItem(String id) async {
    return const Right(unit);
  }
}
