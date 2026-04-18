import '../../../feed/data/models/feed_item_model.dart';
import '../../../feed/domain/entities/feed_item.dart';
import '../../domain/entities/home_feed_page.dart';

/// Data model for HomeFeedPage, with JSON serialization.
class HomeFeedPageModel extends HomeFeedPage {
  HomeFeedPageModel({
    super.items = const <FeedItem>[],
    super.hasMore = false,
    super.nextPage,
    super.nextPageToken,
  });

  factory HomeFeedPageModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems =
        json['items'] as List<dynamic>? ?? const <dynamic>[];

    return HomeFeedPageModel(
      items: rawItems
          .map(
            (dynamic item) =>
                FeedItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      hasMore: json['hasMore'] as bool? ?? false,
      nextPage: json['nextPage'] as int?,
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'items': items
        .map(
          (FeedItem item) => <String, dynamic>{
            'id': item.id,
            'title': item.title,
            'subtitle': item.subtitle,
            'imageUrl': item.imageUrl,
            'metadata': item.metadata,
            'isBookmarked': item.isBookmarked,
          },
        )
        .toList(growable: false),
    'hasMore': hasMore,
    'nextPage': nextPage,
    'nextPageToken': nextPageToken,
  };
}
