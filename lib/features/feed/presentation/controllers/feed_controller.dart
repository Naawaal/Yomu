import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/feed_local_datasource.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/feed_filter.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/usecases/get_feed_items_usecase.dart';
import '../../domain/usecases/refresh_feed_usecase.dart';

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
  return FeedRepositoryImpl(
    remoteDataSource: ref.watch(feedRemoteDataSourceProvider),
    localDataSource: ref.watch(feedLocalDataSourceProvider),
  );
}

/// Provides the get-feed-items use case.
@riverpod
GetFeedItemsUseCase getFeedItemsUseCase(Ref ref) {
  return GetFeedItemsUseCase(ref.watch(feedRepositoryProvider));
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
      final List<FeedItem> nextItems = await useCase(
        GetFeedItemsParams(
          filter: current.filter,
          page: nextPage,
          pageSize: _defaultPageSize,
        ),
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
    final List<FeedItem> items = await useCase(
      GetFeedItemsParams(filter: filter, page: 1, pageSize: _defaultPageSize),
    );

    return FeedViewState(
      items: items,
      filter: filter,
      page: 1,
      hasMore: items.length >= _defaultPageSize,
      lastSyncedAt: DateTime.now(),
    );
  }
}
