// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedLocalDataSourceHash() =>
    r'31940afef33124b8d171540c2b33274e901ca7d2';

/// Provides the feed local datasource implementation.
///
/// Copied from [feedLocalDataSource].
@ProviderFor(feedLocalDataSource)
final feedLocalDataSourceProvider =
    AutoDisposeProvider<FeedLocalDataSource>.internal(
      feedLocalDataSource,
      name: r'feedLocalDataSourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedLocalDataSourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedLocalDataSourceRef = AutoDisposeProviderRef<FeedLocalDataSource>;
String _$feedRemoteDataSourceHash() =>
    r'90e791aaa44fc431ff181fff5cfac23de6d661c9';

/// Provides the feed remote datasource implementation.
///
/// Copied from [feedRemoteDataSource].
@ProviderFor(feedRemoteDataSource)
final feedRemoteDataSourceProvider =
    AutoDisposeProvider<FeedRemoteDataSource>.internal(
      feedRemoteDataSource,
      name: r'feedRemoteDataSourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedRemoteDataSourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedRemoteDataSourceRef = AutoDisposeProviderRef<FeedRemoteDataSource>;
String _$feedRepositoryHash() => r'803e4e2913f4cfb80a5d7a3b66dc38ef097a149d';

/// Provides the feed repository implementation.
///
/// Copied from [feedRepository].
@ProviderFor(feedRepository)
final feedRepositoryProvider = AutoDisposeProvider<FeedRepository>.internal(
  feedRepository,
  name: r'feedRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedRepositoryRef = AutoDisposeProviderRef<FeedRepository>;
String _$getFeedItemsUseCaseHash() =>
    r'd880b1bf082b496a5d5dca1b2b4fe9f1bb52d591';

/// Provides the get-feed-items use case.
///
/// Copied from [getFeedItemsUseCase].
@ProviderFor(getFeedItemsUseCase)
final getFeedItemsUseCaseProvider =
    AutoDisposeProvider<GetFeedItemsUseCase>.internal(
      getFeedItemsUseCase,
      name: r'getFeedItemsUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getFeedItemsUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetFeedItemsUseCaseRef = AutoDisposeProviderRef<GetFeedItemsUseCase>;
String _$refreshFeedUseCaseHash() =>
    r'22090e5e25f40f23d57314092509bc1bbccb76c6';

/// Provides the refresh-feed use case.
///
/// Copied from [refreshFeedUseCase].
@ProviderFor(refreshFeedUseCase)
final refreshFeedUseCaseProvider =
    AutoDisposeProvider<RefreshFeedUseCase>.internal(
      refreshFeedUseCase,
      name: r'refreshFeedUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$refreshFeedUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RefreshFeedUseCaseRef = AutoDisposeProviderRef<RefreshFeedUseCase>;
String _$feedControllerHash() => r'f3d44163941415491f65e7598f047466b8764479';

/// Async controller for loading, filtering, and refreshing feed state.
///
/// Copied from [FeedController].
@ProviderFor(FeedController)
final feedControllerProvider =
    AutoDisposeAsyncNotifierProvider<FeedController, FeedViewState>.internal(
      FeedController.new,
      name: r'feedControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FeedController = AutoDisposeAsyncNotifier<FeedViewState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
