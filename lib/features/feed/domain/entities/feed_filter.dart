/// Sort options available for feed results.
enum FeedSortOrder {
  /// Newest updates first.
  newestFirst,

  /// Oldest updates first.
  oldestFirst,
}

/// Immutable filter criteria for querying feed items.
class FeedFilter {
  /// Creates a feed filter.
  const FeedFilter({
    this.query = '',
    this.includeRead = true,
    this.sortOrder = FeedSortOrder.newestFirst,
  });

  /// Empty/default filter used by initial feed load.
  static const FeedFilter initial = FeedFilter();

  /// Free-text query used for local or remote filtering.
  final String query;

  /// Whether read items are included in results.
  final bool includeRead;

  /// Sort order applied to returned items.
  final FeedSortOrder sortOrder;

  /// Returns a copy with updated properties.
  FeedFilter copyWith({
    String? query,
    bool? includeRead,
    FeedSortOrder? sortOrder,
  }) {
    return FeedFilter(
      query: query ?? this.query,
      includeRead: includeRead ?? this.includeRead,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
