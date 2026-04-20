import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/source_runtime_page.dart';
import '../repositories/i_source_catalog_repository.dart';

/// Use case for loading one source's popular catalog page.
class GetSourcePopularUseCase {
  /// Creates a popular-catalog use case.
  const GetSourcePopularUseCase(this._repository);

  final ISourceCatalogRepository _repository;

  /// Executes one popular query for a source.
  Future<Either<Failure, SourceRuntimePage>> call({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.getPopular(
      sourceId: sourceId,
      page: page,
      pageSize: pageSize,
    );
  }
}
