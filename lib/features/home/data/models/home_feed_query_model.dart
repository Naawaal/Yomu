import '../../domain/entities/home_feed_query.dart';

/// Data model for HomeFeedQuery, with JSON serialization.
class HomeFeedQueryModel extends HomeFeedQuery {
  HomeFeedQueryModel({
    super.query = '',
    super.sourceIds = const <String>[],
    super.includeRead = false,
    super.chronologicalGlobal = false,
    super.page = 1,
    super.pageSize = 20,
  });

  factory HomeFeedQueryModel.fromJson(Map<String, dynamic> json) {
    return HomeFeedQueryModel(
      query: json['query'] as String? ?? '',
      sourceIds: (json['sourceIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic sourceId) => sourceId as String)
          .toList(growable: false),
      includeRead: json['includeRead'] as bool? ?? false,
      chronologicalGlobal: json['chronologicalGlobal'] as bool? ?? false,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'query': query,
    'sourceIds': sourceIds,
    'includeRead': includeRead,
    'chronologicalGlobal': chronologicalGlobal,
    'page': page,
    'pageSize': pageSize,
  };
}
