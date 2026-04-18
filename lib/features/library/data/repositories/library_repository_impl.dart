import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../../domain/entities/library_entry.dart';
import '../../domain/repositories/i_library_repository.dart';
import '../datasources/library_remote_datasource.dart';
import '../models/library_entry_model.dart';

/// Implementation of ILibraryRepository with datasource error mapping.
class LibraryRepositoryImpl implements ILibraryRepository {
  LibraryRepositoryImpl(this._remoteDataSource);

  final LibraryRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<LibraryEntry>>> getLibraryHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final List<LibraryEntryModel> entries = await _remoteDataSource
          .getLibraryHistory(page: page, pageSize: pageSize);
      return Right(
        entries
            .map((LibraryEntryModel entry) => entry as LibraryEntry)
            .toList(growable: false),
      );
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> syncReaderProgress(LibraryEntry entry) async {
    try {
      final LibraryEntryModel model = _toModel(entry);
      await _remoteDataSource.syncReaderProgress(model);
      return const Right(unit);
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  LibraryEntryModel _toModel(LibraryEntry entry) {
    return LibraryEntryModel(
      id: entry.id,
      title: entry.title,
      coverImageUrl: entry.coverImageUrl,
      currentChapter: entry.currentChapter,
      latestChapter: entry.latestChapter,
      progress: entry.progress,
      lastReadAt: entry.lastReadAt,
      status: entry.status,
    );
  }
}
