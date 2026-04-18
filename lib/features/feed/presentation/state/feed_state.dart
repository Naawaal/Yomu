import '../../domain/entities/feed_item.dart';

/// Sealed class representing all possible feed UI states.
abstract class FeedState {
  const FeedState();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedData extends FeedState {
  const FeedData(this.items);
  final List<FeedItem> items;
}

class FeedEmpty extends FeedState {
  const FeedEmpty();
}

class FeedError extends FeedState {
  const FeedError(this.message);
  final String message;
}
