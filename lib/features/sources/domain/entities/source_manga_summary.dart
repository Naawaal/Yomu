import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Lightweight manga summary returned by source runtime queries.
@immutable
class SourceMangaSummary extends Equatable {
  const SourceMangaSummary({
    required this.id,
    required this.sourceId,
    required this.title,
    this.thumbnailUrl,
    this.subtitle,
  });

  final String id;
  final String sourceId;
  final String title;
  final String? thumbnailUrl;
  final String? subtitle;

  @override
  List<Object?> get props => <Object?>[
    id,
    sourceId,
    title,
    thumbnailUrl,
    subtitle,
  ];
}
