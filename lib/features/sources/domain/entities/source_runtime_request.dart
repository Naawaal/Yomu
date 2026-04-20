import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Supported source-runtime operations for bridge execution.
enum SourceRuntimeOperation { latest, popular, search }

/// Immutable request payload for source runtime execution.
@immutable
class SourceRuntimeRequest extends Equatable {
  const SourceRuntimeRequest({
    required this.sourceId,
    required this.operation,
    this.query = '',
    this.page = 1,
    this.pageSize = 20,
  }) : assert(page > 0, 'page must be greater than 0'),
       assert(pageSize > 0, 'pageSize must be greater than 0');

  final String sourceId;
  final SourceRuntimeOperation operation;
  final String query;
  final int page;
  final int pageSize;

  @override
  List<Object?> get props => <Object?>[
    sourceId,
    operation,
    query,
    page,
    pageSize,
  ];
}
