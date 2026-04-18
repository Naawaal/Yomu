import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Domain entity representing a single feed item.
@immutable
class FeedItem extends Equatable {
  const FeedItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.metadata,
    required this.isBookmarked,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String metadata;
  final bool isBookmarked;

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    imageUrl,
    metadata,
    isBookmarked,
  ];
}
