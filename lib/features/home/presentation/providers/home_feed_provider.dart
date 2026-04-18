import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/home_feed_remote_datasource.dart';
import '../../data/repositories/home_feed_repository_impl.dart';
import '../../../feed/domain/entities/feed_item.dart';
import '../../domain/entities/home_feed_page.dart';
import '../../domain/entities/home_feed_query.dart';
import '../../domain/repositories/i_home_feed_repository.dart';
import '../../domain/usecases/get_home_feed_page_usecase.dart';
import '../../domain/usecases/refresh_home_feed_usecase.dart';

/// Provides the Home feed remote datasource implementation.
final homeFeedRemoteDataSourceProvider = Provider<HomeFeedRemoteDataSource>((
  Ref ref,
) {
  return MockHomeFeedRemoteDataSource();
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

/// Async notifier for Home feed loading, refresh, and pagination flows.
class HomeFeedNotifier extends AsyncNotifier<HomeFeedPage> {
  HomeFeedQuery _query = HomeFeedQuery.initial;

  @override
  Future<HomeFeedPage> build() async {
    return HomeFeedPage.empty;
  }

  /// Loads Home feed for the provided query.
  Future<void> fetch({HomeFeedQuery? query}) async {
    _query = query ?? _query;

    state = const AsyncLoading<HomeFeedPage>();

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
}

/// Provides HomeFeedNotifier for presentation consumers.
final homeFeedNotifierProvider =
    AsyncNotifierProvider<HomeFeedNotifier, HomeFeedPage>(HomeFeedNotifier.new);
