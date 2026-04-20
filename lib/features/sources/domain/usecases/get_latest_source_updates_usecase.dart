import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/source_runtime_page.dart';
import '../repositories/i_source_catalog_repository.dart';

/// Use case for latest-updates runtime queries against one source.
class GetLatestSourceUpdatesUseCase {
  /// Creates a latest-updates runtime use case.
  const GetLatestSourceUpdatesUseCase(this._repository);

  final ISourceCatalogRepository _repository;

  /// Executes one latest-updates request for the given source.
  Future<Either<Failure, SourceRuntimePage>> call({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.getLatest(
      sourceId: sourceId,
      page: page,
      pageSize: pageSize,
    );
  }
}
