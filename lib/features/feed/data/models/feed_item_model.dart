import '../../domain/entities/feed_item.dart';

/// Data-transfer model for [FeedItem] serialization.
class FeedItemModel extends FeedItem {
  /// Creates a feed item model.
  const FeedItemModel({
    required super.id,
    required super.sourceName,
    required super.title,
    required super.subtitle,
    required super.updatedAt,
    required super.isRead,
    super.coverImageUrl,
  });

  /// Creates a model from a JSON-like map payload.
  factory FeedItemModel.fromMap(Map<String, Object?> map) {
    return FeedItemModel(
      id: map['id'] as String? ?? '',
      sourceName: map['sourceName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isRead: map['isRead'] as bool? ?? false,
      coverImageUrl: map['coverImageUrl'] as String?,
    );
  }

  /// Creates a model from the equivalent domain entity.
  factory FeedItemModel.fromEntity(FeedItem item) {
    return FeedItemModel(
      id: item.id,
      sourceName: item.sourceName,
      title: item.title,
      subtitle: item.subtitle,
      updatedAt: item.updatedAt,
      isRead: item.isRead,
      coverImageUrl: item.coverImageUrl,
    );
  }

  /// Converts this model into a serializable map payload.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'sourceName': sourceName,
      'title': title,
      'subtitle': subtitle,
      'updatedAt': updatedAt.toIso8601String(),
      'isRead': isRead,
      'coverImageUrl': coverImageUrl,
    };
  }
}
