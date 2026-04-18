import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Immutable query parameters for loading Home hub feed items.
@immutable
class HomeFeedQuery extends Equatable {
  /// Creates Home feed query parameters.
  HomeFeedQuery({
    this.query = '',
    List<String> sourceIds = const <String>[],
    this.includeRead = false,
    this.chronologicalGlobal = false,
    this.page = 1,
    this.pageSize = 20,
  }) : assert(page > 0, 'page must be greater than 0'),
       assert(pageSize > 0, 'pageSize must be greater than 0'),
       sourceIds = List<String>.unmodifiable(sourceIds);

  /// Empty/default query used for initial Home feed requests.
  static final HomeFeedQuery initial = HomeFeedQuery();

  /// Free-text query used for filtering feed items.
  final String query;

  /// Source identifiers included in the feed.
  ///
  /// Empty list means all active sources.
  final List<String> sourceIds;

  /// Whether read items are included in results.
  final bool includeRead;

  /// Whether global feed results should be sorted chronologically.
  final bool chronologicalGlobal;

  /// 1-based page index.
  final int page;

  /// Number of items requested per page.
  final int pageSize;

  /// Returns a copy with updated properties.
  HomeFeedQuery copyWith({
    String? query,
    List<String>? sourceIds,
    bool? includeRead,
    bool? chronologicalGlobal,
    int? page,
    int? pageSize,
  }) {
    return HomeFeedQuery(
      query: query ?? this.query,
      sourceIds: sourceIds ?? this.sourceIds,
      includeRead: includeRead ?? this.includeRead,
      chronologicalGlobal: chronologicalGlobal ?? this.chronologicalGlobal,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
    query,
    sourceIds,
    includeRead,
    chronologicalGlobal,
    page,
    pageSize,
  ];
}
