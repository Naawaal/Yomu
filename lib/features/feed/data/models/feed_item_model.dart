import '../../domain/entities/feed_item.dart';

/// Data model for FeedItem, with JSON serialization.
class FeedItemModel extends FeedItem {
  const FeedItemModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.imageUrl,
    required super.metadata,
    required super.isBookmarked,
  });

  factory FeedItemModel.fromJson(Map<String, dynamic> json) {
    return FeedItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['imageUrl'] as String,
      metadata: json['metadata'] as String,
      isBookmarked: json['isBookmarked'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'metadata': metadata,
    'isBookmarked': isBookmarked,
  };
}
