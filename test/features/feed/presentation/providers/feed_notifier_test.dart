import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yomu/features/feed/presentation/providers/feed_notifier.dart';
import 'package:yomu/features/feed/presentation/state/feed_state.dart';

void main() {
  group('FeedNotifier', () {
    test('initial state is FeedLoading', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final FeedState state = container.read(feedNotifierProvider);
      expect(state, isA<FeedLoading>());
    });

    test('provider exposes FeedNotifier notifier', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final FeedNotifier notifier = container.read(
        feedNotifierProvider.notifier,
      );
      expect(notifier, isA<FeedNotifier>());
    });
  });
}
