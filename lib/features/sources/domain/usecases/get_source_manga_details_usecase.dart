import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/source_manga_details.dart';
import '../repositories/i_source_catalog_repository.dart';

/// Use case for loading one manga's details from a source.
class GetSourceMangaDetailsUseCase {
  /// Creates a source-manga-details use case.
  const GetSourceMangaDetailsUseCase(this._repository);

  final ISourceCatalogRepository _repository;

  /// Retrieves details for one manga id in a source catalog.
  Future<Either<Failure, SourceMangaDetails>> call({
    required String sourceId,
    required String mangaId,
  }) {
    return _repository.getDetails(sourceId: sourceId, mangaId: mangaId);
  }
}
