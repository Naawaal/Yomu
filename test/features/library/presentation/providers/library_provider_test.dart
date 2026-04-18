import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/features/library/domain/entities/library_entry.dart';
import 'package:yomu/features/library/presentation/providers/library_provider.dart';

void main() {
  group('LibraryNotifier', () {
    test('provider exposes LibraryNotifier notifier', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final LibraryNotifier notifier = container.read(
        libraryNotifierProvider.notifier,
      );

      expect(notifier, isA<LibraryNotifier>());
    });

    test('fetchHistory loads entries from datasource', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final LibraryNotifier notifier = container.read(
        libraryNotifierProvider.notifier,
      );

      await notifier.fetchHistory();
      final AsyncValue<List<LibraryEntry>> state = container.read(
        libraryNotifierProvider,
      );

      expect(state.hasValue, isTrue);
      expect(state.value, isNotNull);
      expect(state.value!, isNotEmpty);
    });
  });
}
