import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../../../extensions/domain/entities/extension_item.dart';
import '../../../extensions/domain/repositories/extension_repository.dart';
import '../../domain/entities/source_handle.dart';
import '../../domain/entities/source_manga_details.dart';
import '../../domain/entities/source_manga_summary.dart';
import '../../domain/entities/source_runtime_page.dart';
import '../../domain/entities/source_runtime_request.dart';
import '../../domain/repositories/i_source_catalog_repository.dart';
import '../../domain/repositories/i_source_runtime_repository.dart';

/// Composes extension metadata with runtime source execution operations.
class SourceCatalogRepositoryImpl implements ISourceCatalogRepository {
  /// Creates a composed source catalog repository.
  const SourceCatalogRepositoryImpl({
    required ExtensionRepository extensionRepository,
    required ISourceRuntimeRepository runtimeRepository,
  }) : _extensionRepository = extensionRepository,
       _runtimeRepository = runtimeRepository;

  final ExtensionRepository _extensionRepository;
  final ISourceRuntimeRepository _runtimeRepository;

  @override
  Future<Either<Failure, SourceRuntimePage>> getLatest({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Either<Failure, SourceHandle> handleResult = await _resolveHandle(
      sourceId,
    );
    return handleResult.fold(
      Left.new,
      (SourceHandle handle) => _executeWithHandle(
        handle: handle,
        operation: SourceRuntimeOperation.latest,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  @override
  Future<Either<Failure, SourceRuntimePage>> getPopular({
    required String sourceId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Either<Failure, SourceHandle> handleResult = await _resolveHandle(
      sourceId,
    );
    return handleResult.fold(
      Left.new,
      (SourceHandle handle) => _executeWithHandle(
        handle: handle,
        operation: SourceRuntimeOperation.popular,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  @override
  Future<Either<Failure, SourceRuntimePage>> search({
    required String sourceId,
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Either<Failure, SourceHandle> handleResult = await _resolveHandle(
      sourceId,
    );
    return handleResult.fold(
      Left.new,
      (SourceHandle handle) => _executeWithHandle(
        handle: handle,
        operation: SourceRuntimeOperation.search,
        query: query,
        page: page,
        pageSize: pageSize,
      ),
    );
  }

  @override
  Future<Either<Failure, SourceMangaDetails>> getDetails({
    required String sourceId,
    required String mangaId,
  }) async {
    final Either<Failure, SourceHandle> handleResult = await _resolveHandle(
      sourceId,
    );

    return handleResult.fold(
      Left.new,
      (SourceHandle handle) => Right(
        SourceMangaDetails(
          id: mangaId,
          sourceId: handle.sourceId,
          title: handle.displayName,
          description: 'Details runtime operation is not implemented yet.',
          thumbnailUrl: null,
          author: null,
          status: null,
          genres: const <String>[],
        ),
      ),
    );
  }

  Future<Either<Failure, SourceRuntimePage>> _executeWithHandle({
    required SourceHandle handle,
    required SourceRuntimeOperation operation,
    required int page,
    required int pageSize,
    String query = '',
  }) async {
    final Either<Failure, SourceRuntimePage> runtimeResult =
        await _runtimeRepository.execute(
          SourceRuntimeRequest(
            sourceId: handle.sourceId,
            operation: operation,
            query: query,
            page: page,
            pageSize: pageSize,
          ),
        );

    return runtimeResult.map(
      (SourceRuntimePage pageResult) => _enrichRuntimePage(pageResult, handle),
    );
  }

  SourceRuntimePage _enrichRuntimePage(
    SourceRuntimePage page,
    SourceHandle handle,
  ) {
    final List<SourceMangaSummary> items = page.items
        .map((SourceMangaSummary item) {
          return SourceMangaSummary(
            id: item.id,
            sourceId: item.sourceId.isEmpty ? handle.sourceId : item.sourceId,
            title: item.title,
            thumbnailUrl: item.thumbnailUrl,
            subtitle: item.subtitle,
          );
        })
        .toList(growable: false);

    return SourceRuntimePage(
      sourceId: page.sourceId.isEmpty ? handle.sourceId : page.sourceId,
      items: items,
      hasMore: page.hasMore,
      nextPage: page.nextPage,
      nextPageToken: page.nextPageToken,
    );
  }

  Future<Either<Failure, SourceHandle>> _resolveHandle(String sourceId) async {
    final List<ExtensionItem> extensions;
    try {
      extensions = await _extensionRepository.getAvailableExtensions();
    } catch (error) {
      return Left(
        SourceRuntimeFailure(
          code: SourceFailureCode.runtimeExecutionFailed,
          message: 'Failed to resolve source metadata: $error',
        ),
      );
    }

    ExtensionItem? matched;
    for (final ExtensionItem item in extensions) {
      if (item.packageName == sourceId) {
        matched = item;
        break;
      }
    }

    if (matched == null) {
      return Left(
        SourceRuntimeFailure(
          code: SourceFailureCode.unknown,
          message: 'Source is unavailable: $sourceId',
        ),
      );
    }
    if (!matched.isInstalled) {
      return Left(
        SourceRuntimeFailure(
          code: SourceFailureCode.unknown,
          message: 'Source is not installed: $sourceId',
        ),
      );
    }
    if (matched.trustStatus != ExtensionTrustStatus.trusted) {
      return Left(
        SourceTrustFailure(
          code: SourceFailureCode.sourceNotTrusted,
          message: 'Source is not trusted: $sourceId',
        ),
      );
    }

    return Right(
      SourceHandle(
        sourceId: matched.packageName,
        packageName: matched.packageName,
        displayName: matched.name,
        language: matched.language,
        isTrusted: true,
      ),
    );
  }
}
