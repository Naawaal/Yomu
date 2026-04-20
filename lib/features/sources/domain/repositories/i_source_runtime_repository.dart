import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../entities/source_runtime_page.dart';
import '../entities/source_runtime_request.dart';

/// Contract for runtime source execution operations.
abstract class ISourceRuntimeRepository {
  /// Executes one runtime operation and returns a typed page payload.
  Future<Either<Failure, SourceRuntimePage>> execute(
    SourceRuntimeRequest request,
  );
}
