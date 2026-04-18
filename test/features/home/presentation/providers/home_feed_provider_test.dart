import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/features/home/domain/entities/home_feed_page.dart';
import 'package:yomu/features/home/presentation/providers/home_feed_provider.dart';

void main() {
  group('HomeFeedNotifier', () {
    test('provider exposes HomeFeedNotifier notifier', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final HomeFeedNotifier notifier = container.read(
        homeFeedNotifierProvider.notifier,
      );

      expect(notifier, isA<HomeFeedNotifier>());
    });

    test('fetch loads page with items from datasource', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final HomeFeedNotifier notifier = container.read(
        homeFeedNotifierProvider.notifier,
      );

      await notifier.fetch();
      final AsyncValue<HomeFeedPage> state = container.read(
        homeFeedNotifierProvider,
      );

      expect(state.hasValue, isTrue);
      expect(state.value, isNotNull);
      expect(state.value!.items, isNotEmpty);
    });
  });
}
