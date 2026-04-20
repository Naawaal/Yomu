import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/source_runtime_page.dart';
import '../repositories/i_source_catalog_repository.dart';

/// Use case for searching one source catalog.
class SearchSourceCatalogUseCase {
  /// Creates a source-catalog search use case.
  const SearchSourceCatalogUseCase(this._repository);

  final ISourceCatalogRepository _repository;

  /// Executes a paged search on a source.
  Future<Either<Failure, SourceRuntimePage>> call({
    required String sourceId,
    required String query,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.search(
      sourceId: sourceId,
      query: query,
      page: page,
      pageSize: pageSize,
    );
  }
}
