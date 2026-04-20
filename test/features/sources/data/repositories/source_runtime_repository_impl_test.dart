import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/failure.dart';
import 'package:yomu/features/sources/data/datasources/source_runtime_bridge_datasource.dart';
import 'package:yomu/features/sources/data/repositories/source_runtime_repository_impl.dart';
import 'package:yomu/features/sources/domain/entities/source_runtime_page.dart';
import 'package:yomu/features/sources/domain/entities/source_runtime_request.dart';

class _FakeSourceRuntimeBridgeDataSource
    implements SourceRuntimeBridgeDataSource {
  _FakeSourceRuntimeBridgeDataSource({this.page, this.error});

  final SourceRuntimePage? page;
  final Object? error;

  SourceRuntimeRequest? lastRequest;

  @override
  Future<SourceRuntimePage> execute(SourceRuntimeRequest request) async {
    lastRequest = request;
    if (error != null) {
      throw error!;
    }

    return page!;
  }
}

void main() {
  group('SourceRuntimeRepositoryImpl.execute', () {
    const SourceRuntimeRequest request = SourceRuntimeRequest(
      sourceId: 'source.runtime',
      operation: SourceRuntimeOperation.latest,
    );

    test('returns Right when bridge datasource succeeds', () async {
      final _FakeSourceRuntimeBridgeDataSource bridgeDataSource =
          _FakeSourceRuntimeBridgeDataSource(
            page: SourceRuntimePage(sourceId: 'source.runtime'),
          );
      final SourceRuntimeRepositoryImpl repository =
          SourceRuntimeRepositoryImpl(bridgeDataSource);

      final Either<Failure, SourceRuntimePage> result = await repository
          .execute(request);

      expect(result.isRight(), isTrue);
      expect(
        result.getOrElse(() => throw StateError('missing page')).sourceId,
        'source.runtime',
      );
      expect(bridgeDataSource.lastRequest, request);
    });

    test('maps FormatException with detail into ParseFailure', () async {
      final _FakeSourceRuntimeBridgeDataSource bridgeDataSource =
          _FakeSourceRuntimeBridgeDataSource(
            error: FormatException('invalid cursor payload'),
          );
      final SourceRuntimeRepositoryImpl repository =
          SourceRuntimeRepositoryImpl(bridgeDataSource);

      final Either<Failure, SourceRuntimePage> result = await repository
          .execute(request);

      expect(result.isLeft(), isTrue);
      final Failure failure = result.fold(
        (Failure f) => f,
        (_) => throw StateError('expected failure'),
      );
      expect(failure, isA<ParseFailure>());
      expect(
        failure.message,
        'Failed to parse source runtime payload: invalid cursor payload',
      );
    });

    test(
      'maps FormatException with blank message into deterministic ParseFailure',
      () async {
        final _FakeSourceRuntimeBridgeDataSource bridgeDataSource =
            _FakeSourceRuntimeBridgeDataSource(error: FormatException('   '));
        final SourceRuntimeRepositoryImpl repository =
            SourceRuntimeRepositoryImpl(bridgeDataSource);

        final Either<Failure, SourceRuntimePage> result = await repository
            .execute(request);

        final Failure failure = result.fold(
          (Failure f) => f,
          (_) => throw StateError('expected failure'),
        );
        expect(failure, isA<ParseFailure>());
        expect(failure.message, 'Failed to parse source runtime payload');
      },
    );

    test('maps bridge exceptions through source failure mapper', () async {
      final _FakeSourceRuntimeBridgeDataSource bridgeDataSource =
          _FakeSourceRuntimeBridgeDataSource(
            error: const SourceRuntimeBridgeException(
              code: SourceFailureCode.unsupportedCapability,
              message: 'Search is unavailable',
            ),
          );
      final SourceRuntimeRepositoryImpl repository =
          SourceRuntimeRepositoryImpl(bridgeDataSource);

      final Either<Failure, SourceRuntimePage> result = await repository
          .execute(request);

      final Failure failure = result.fold(
        (Failure f) => f,
        (_) => throw StateError('expected failure'),
      );
      expect(failure, isA<SourceCapabilityFailure>());
      expect(
        (failure as SourceFailure).code,
        SourceFailureCode.unsupportedCapability,
      );
      expect(failure.message, 'Search is unavailable');
    });

    test('maps source trust bridge failures into SourceTrustFailure', () async {
      final _FakeSourceRuntimeBridgeDataSource bridgeDataSource =
          _FakeSourceRuntimeBridgeDataSource(
            error: const SourceRuntimeBridgeException(
              code: SourceFailureCode.sourceNotTrusted,
              message: 'Source trust is required',
            ),
          );
      final SourceRuntimeRepositoryImpl repository =
          SourceRuntimeRepositoryImpl(bridgeDataSource);

      final Either<Failure, SourceRuntimePage> result = await repository
          .execute(request);

      final Failure failure = result.fold(
        (Failure f) => f,
        (_) => throw StateError('expected failure'),
      );
      expect(failure, isA<SourceTrustFailure>());
      expect(
        (failure as SourceFailure).code,
        SourceFailureCode.sourceNotTrusted,
      );
      expect(failure.message, 'Source trust is required');
    });

    test(
      'maps unknown bridge failure codes to SourceRuntimeFailure with unknown code',
      () async {
        final _FakeSourceRuntimeBridgeDataSource bridgeDataSource =
            _FakeSourceRuntimeBridgeDataSource(
              error: const SourceRuntimeBridgeException(
                code: 'SOMETHING_NEW',
                message: 'Unexpected bridge error',
              ),
            );
        final SourceRuntimeRepositoryImpl repository =
            SourceRuntimeRepositoryImpl(bridgeDataSource);

        final Either<Failure, SourceRuntimePage> result = await repository
            .execute(request);

        final Failure failure = result.fold(
          (Failure f) => f,
          (_) => throw StateError('expected failure'),
        );
        expect(failure, isA<SourceRuntimeFailure>());
        expect((failure as SourceFailure).code, SourceFailureCode.unknown);
        expect(failure.message, 'Unexpected bridge error');
      },
    );
  });
}
