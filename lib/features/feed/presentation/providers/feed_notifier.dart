import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/repositories/i_feed_repository.dart';
import '../../domain/usecases/get_feed_items_usecase.dart';
import '../../domain/usecases/bookmark_feed_item_usecase.dart';
import '../../domain/usecases/unbookmark_feed_item_usecase.dart';
import '../state/feed_state.dart';

part 'feed_notifier.g.dart';

/// Provides a mock remote data source for the feed.
@riverpod
FeedRemoteDataSource feedRemoteDataSource(Ref ref) {
  return MockFeedRemoteDataSource();
}

/// Provides the feed repository implementation.
@riverpod
IFeedRepository feedRepository(Ref ref) {
  final remoteDataSource = ref.watch(feedRemoteDataSourceProvider);
  return FeedRepositoryImpl(remoteDataSource);
}

/// Provides the GetFeedItemsUseCase.
@riverpod
GetFeedItemsUseCase getFeedItemsUseCase(Ref ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return GetFeedItemsUseCase(repository);
}

/// Provides the BookmarkFeedItemUseCase.
@riverpod
BookmarkFeedItemUseCase bookmarkFeedItemUseCase(Ref ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return BookmarkFeedItemUseCase(repository);
}

/// Provides the UnbookmarkFeedItemUseCase.
@riverpod
UnbookmarkFeedItemUseCase unbookmarkFeedItemUseCase(Ref ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return UnbookmarkFeedItemUseCase(repository);
}

@riverpod
class FeedNotifier extends _$FeedNotifier {
  late final GetFeedItemsUseCase _getFeedItems;
  late final BookmarkFeedItemUseCase _bookmarkFeedItem;
  late final UnbookmarkFeedItemUseCase _unbookmarkFeedItem;

  @override
  FeedState build() {
    _getFeedItems = ref.read(getFeedItemsUseCaseProvider);
    _bookmarkFeedItem = ref.read(bookmarkFeedItemUseCaseProvider);
    _unbookmarkFeedItem = ref.read(unbookmarkFeedItemUseCaseProvider);
    return const FeedLoading();
  }

  Future<void> fetch({Map<String, dynamic>? filters, int? page}) async {
    state = const FeedLoading();
    final result = await _getFeedItems(filters: filters, page: page);
    state = result.fold(
      (failure) => FeedError(failure.message),
      (items) => items.isEmpty ? const FeedEmpty() : FeedData(items),
    );
  }

  Future<void> bookmark(String id) async {
    final result = await _bookmarkFeedItem(id);
    result.fold(
      (failure) => state = FeedError(failure.message),
      (_) => fetch(),
    );
  }

  Future<void> unbookmark(String id) async {
    final result = await _unbookmarkFeedItem(id);
    result.fold(
      (failure) => state = FeedError(failure.message),
      (_) => fetch(),
    );
  }

  Future<void> refresh() async {
    await fetch();
  }
}
