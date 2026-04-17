/// A single item rendered in the user's home feed.
class FeedItem {
  /// Creates a feed item.
  const FeedItem({
    required this.id,
    required this.sourceName,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.isRead,
    this.coverImageUrl,
  });

  /// Stable item identifier.
  final String id;

  /// Human-readable source name.
  final String sourceName;

  /// Primary text shown in feed cards.
  final String title;

  /// Secondary text shown in feed cards.
  final String subtitle;

  /// Last update timestamp for this item.
  final DateTime updatedAt;

  /// Whether the user has read this item update.
  final bool isRead;

  /// Optional remote image URL for the feed card thumbnail.
  final String? coverImageUrl;
}
