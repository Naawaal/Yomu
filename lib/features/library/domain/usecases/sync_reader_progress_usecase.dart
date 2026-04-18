import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/library_entry.dart';
import '../repositories/i_library_repository.dart';

/// Use case for syncing reader progress into library state.
class SyncReaderProgressUseCase {
  const SyncReaderProgressUseCase(this._repository);

  final ILibraryRepository _repository;

  Future<Either<Failure, Unit>> call(LibraryEntry entry) {
    return _repository.syncReaderProgress(entry);
  }
}
