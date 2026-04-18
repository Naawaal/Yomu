import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../feed/domain/entities/feed_item.dart';

/// Immutable paged payload for Home feed results.
@immutable
class HomeFeedPage extends Equatable {
  /// Creates one page of Home feed results.
  HomeFeedPage({
    List<FeedItem> items = const <FeedItem>[],
    this.hasMore = false,
    this.nextPage,
    this.nextPageToken,
  }) : assert(
         nextPage == null || nextPage > 0,
         'nextPage must be greater than 0',
       ),
       items = List<FeedItem>.unmodifiable(items);

  /// Feed items included in the current page.
  final List<FeedItem> items;

  /// Whether more pages are available.
  final bool hasMore;

  /// Next page index for number-based pagination.
  final int? nextPage;

  /// Next page cursor for token-based pagination.
  final String? nextPageToken;

  /// Empty/default page for initial state.
  static final HomeFeedPage empty = HomeFeedPage();

  /// Returns a copy with updated values.
  HomeFeedPage copyWith({
    List<FeedItem>? items,
    bool? hasMore,
    int? nextPage,
    String? nextPageToken,
  }) {
    return HomeFeedPage(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      nextPageToken: nextPageToken ?? this.nextPageToken,
    );
  }

  @override
  List<Object?> get props => <Object?>[items, hasMore, nextPage, nextPageToken];
}
