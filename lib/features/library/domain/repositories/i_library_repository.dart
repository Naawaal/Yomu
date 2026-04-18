import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/library_entry.dart';

/// Abstract repository contract for user's library/history operations.
abstract class ILibraryRepository {
  /// Returns paged reading/history entries for the user library tab.
  Future<Either<Failure, List<LibraryEntry>>> getLibraryHistory({
    int page = 1,
    int pageSize = 20,
  });

  /// Synchronizes reader progress changes into the library state.
  Future<Either<Failure, Unit>> syncReaderProgress(LibraryEntry entry);
}
