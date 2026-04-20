import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/source_manga_details.dart';
import '../entities/source_runtime_page.dart';

/// Contract for source catalog operations across latest/popular/search/details.
abstract class ISourceCatalogRepository {
  /// Returns latest updates for one source.
  Future<Either<Failure, SourceRuntimePage>> getLatest({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  });

  /// Returns popular titles for one source.
  Future<Either<Failure, SourceRuntimePage>> getPopular({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  });

  /// Searches one source catalog for a user query.
  Future<Either<Failure, SourceRuntimePage>> search({
    required String sourceId,
    required String query,
    int page = 1,
    int pageSize = 20,
  });

  /// Returns one title's details from a source catalog.
  Future<Either<Failure, SourceMangaDetails>> getDetails({
    required String sourceId,
    required String mangaId,
  });
}
