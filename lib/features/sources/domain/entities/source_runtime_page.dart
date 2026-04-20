import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'source_manga_summary.dart';

/// Immutable paged response returned by source runtime operations.
@immutable
class SourceRuntimePage extends Equatable {
  SourceRuntimePage({
    required this.sourceId,
    List<SourceMangaSummary> items = const <SourceMangaSummary>[],
    this.hasMore = false,
    this.nextPage,
    this.nextPageToken,
  }) : assert(
         nextPage == null || nextPage > 0,
         'nextPage must be greater than 0',
       ),
       items = List<SourceMangaSummary>.unmodifiable(items);

  final String sourceId;
  final List<SourceMangaSummary> items;
  final bool hasMore;
  final int? nextPage;
  final String? nextPageToken;

  SourceRuntimePage copyWith({
    String? sourceId,
    List<SourceMangaSummary>? items,
    bool? hasMore,
    int? nextPage,
    String? nextPageToken,
  }) {
    return SourceRuntimePage(
      sourceId: sourceId ?? this.sourceId,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      nextPageToken: nextPageToken ?? this.nextPageToken,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    sourceId,
    items,
    hasMore,
    nextPage,
    nextPageToken,
  ];
}
