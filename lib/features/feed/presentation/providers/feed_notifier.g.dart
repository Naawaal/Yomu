// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedRemoteDataSourceHash() =>
    r'90e791aaa44fc431ff181fff5cfac23de6d661c9';

/// Provides a mock remote data source for the feed.
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
String _$feedRepositoryHash() => r'7d71051cc78a6153876b3f73552f41a0e93b3b88';

/// Provides the feed repository implementation.
///
/// Copied from [feedRepository].
@ProviderFor(feedRepository)
final feedRepositoryProvider = AutoDisposeProvider<IFeedRepository>.internal(
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
typedef FeedRepositoryRef = AutoDisposeProviderRef<IFeedRepository>;
String _$getFeedItemsUseCaseHash() =>
    r'7420009fafdba210ac7c7428a3d5935385292c19';

/// Provides the GetFeedItemsUseCase.
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
String _$bookmarkFeedItemUseCaseHash() =>
    r'87192677c73ff2d62ddca0dfdeffdde279fb207b';

/// Provides the BookmarkFeedItemUseCase.
///
/// Copied from [bookmarkFeedItemUseCase].
@ProviderFor(bookmarkFeedItemUseCase)
final bookmarkFeedItemUseCaseProvider =
    AutoDisposeProvider<BookmarkFeedItemUseCase>.internal(
      bookmarkFeedItemUseCase,
      name: r'bookmarkFeedItemUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$bookmarkFeedItemUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BookmarkFeedItemUseCaseRef =
    AutoDisposeProviderRef<BookmarkFeedItemUseCase>;
String _$unbookmarkFeedItemUseCaseHash() =>
    r'beb29f2abe4505a116ce98ff25b791da32f4081b';

/// Provides the UnbookmarkFeedItemUseCase.
///
/// Copied from [unbookmarkFeedItemUseCase].
@ProviderFor(unbookmarkFeedItemUseCase)
final unbookmarkFeedItemUseCaseProvider =
    AutoDisposeProvider<UnbookmarkFeedItemUseCase>.internal(
      unbookmarkFeedItemUseCase,
      name: r'unbookmarkFeedItemUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$unbookmarkFeedItemUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnbookmarkFeedItemUseCaseRef =
    AutoDisposeProviderRef<UnbookmarkFeedItemUseCase>;
String _$feedNotifierHash() => r'99ca1ed5b46f28ad520a933735cdb51f996f0cee';

/// See also [FeedNotifier].
@ProviderFor(FeedNotifier)
final feedNotifierProvider =
    AutoDisposeNotifierProvider<FeedNotifier, FeedState>.internal(
      FeedNotifier.new,
      name: r'feedNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FeedNotifier = AutoDisposeNotifier<FeedState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
