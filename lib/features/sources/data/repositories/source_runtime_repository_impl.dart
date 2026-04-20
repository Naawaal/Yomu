import 'package:dartz/dartz.dart';

import '../../../../core/failure.dart';
import '../../domain/entities/source_runtime_page.dart';
import '../../domain/entities/source_runtime_request.dart';
import '../../domain/repositories/i_source_runtime_repository.dart';
import '../datasources/source_runtime_bridge_datasource.dart';
import '../mappers/source_failure_mapper.dart';

/// Repository implementation for source runtime execution operations.
class SourceRuntimeRepositoryImpl implements ISourceRuntimeRepository {
  /// Creates a source runtime repository implementation.
  const SourceRuntimeRepositoryImpl(this._bridgeDataSource);

  final SourceRuntimeBridgeDataSource _bridgeDataSource;

  @override
  Future<Either<Failure, SourceRuntimePage>> execute(
    SourceRuntimeRequest request,
  ) async {
    try {
      final SourceRuntimePage page = await _bridgeDataSource.execute(request);
      return Right(page);
    } on FormatException catch (exception) {
      return Left(_mapSourceRuntimeParseFailure(exception));
    } on SourceRuntimeBridgeException catch (exception) {
      return Left(
        mapSourceBridgeFailure(
          code: exception.code,
          message: exception.message,
        ),
      );
    } on Exception catch (exception) {
      return Left(
        SourceRuntimeFailure(
          code: SourceFailureCode.runtimeExecutionFailed,
          message: 'Source runtime request failed: $exception',
        ),
      );
    } catch (error) {
      return Left(
        SourceRuntimeFailure(
          code: SourceFailureCode.runtimeExecutionFailed,
          message: 'Source runtime request failed: $error',
        ),
      );
    }
  }
}

ParseFailure _mapSourceRuntimeParseFailure(FormatException exception) {
  final String detail = exception.message.trim();
  if (detail.isEmpty) {
    return const ParseFailure('Failed to parse source runtime payload');
  }

  return ParseFailure('Failed to parse source runtime payload: $detail');
}
