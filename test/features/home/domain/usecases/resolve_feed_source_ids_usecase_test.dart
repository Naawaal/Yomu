import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/features/home/domain/usecases/resolve_feed_source_ids_usecase.dart';

void main() {
  group('ResolveFeedSourceIdsUseCase', () {
    const ResolveFeedSourceIdsUseCase useCase = ResolveFeedSourceIdsUseCase();

    test('returns empty when no installed sources exist', () {
      final List<String> result = useCase(installedSourceIds: const <String>[]);

      expect(result, isEmpty);
    });

    test('prefers user-selected installed sources', () {
      final List<String> result = useCase(
        installedSourceIds: const <String>['a', 'b', 'c'],
        selectedSourceIds: const <String>{'c', 'a'},
        requestedSourceIds: const <String>['b'],
      );

      expect(result, <String>['a', 'c']);
    });

    test('drops stale selected sources that are not installed', () {
      final List<String> result = useCase(
        installedSourceIds: const <String>['a', 'b'],
        selectedSourceIds: const <String>{'z', 'b'},
      );

      expect(result, <String>['b']);
    });

    test('uses requested sources when no valid selection exists', () {
      final List<String> result = useCase(
        installedSourceIds: const <String>['a', 'b', 'c'],
        selectedSourceIds: const <String>{'z'},
        requestedSourceIds: const <String>['c', 'a', 'z', 'c'],
      );

      expect(result, <String>['c', 'a']);
    });

    test('auto-selects the only installed source', () {
      final List<String> result = useCase(
        installedSourceIds: const <String>['single'],
      );

      expect(result, <String>['single']);
    });

    test('returns all installed sources when multiple are installed', () {
      final List<String> result = useCase(
        installedSourceIds: const <String>['a', 'b', 'c'],
      );

      expect(result, <String>['a', 'b', 'c']);
    });

    test('deduplicates installed source IDs while preserving order', () {
      final List<String> result = useCase(
        installedSourceIds: const <String>['a', 'a', '', 'b', 'a', 'c'],
      );

      expect(result, <String>['a', 'b', 'c']);
    });
  });
}
