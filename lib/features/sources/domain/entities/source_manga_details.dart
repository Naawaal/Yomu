import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Detailed manga information returned by one source.
@immutable
class SourceMangaDetails extends Equatable {
  SourceMangaDetails({
    required this.id,
    required this.sourceId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.author,
    this.status,
    List<String> genres = const <String>[],
  }) : genres = List<String>.unmodifiable(genres);

  final String id;
  final String sourceId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? author;
  final String? status;
  final List<String> genres;

  @override
  List<Object?> get props => <Object?>[
    id,
    sourceId,
    title,
    description,
    thumbnailUrl,
    author,
    status,
    genres,
  ];
}
