import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/library_entry.dart';
import '../repositories/i_library_repository.dart';

/// Use case for loading paged library reading/history entries.
class GetLibraryHistoryUseCase {
  const GetLibraryHistoryUseCase(this._repository);

  final ILibraryRepository _repository;

  Future<Either<Failure, List<LibraryEntry>>> call({
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.getLibraryHistory(page: page, pageSize: pageSize);
  }
}
