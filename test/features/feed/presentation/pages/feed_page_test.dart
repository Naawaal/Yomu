import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yomu/features/feed/presentation/pages/feed_page.dart';

void main() {
  group('FeedPage', () {
    testWidgets('renders FeedPage with app bar title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FeedPage())),
      );
      await tester.pump();

      expect(find.text('Feed'), findsWidgets);
    });

    testWidgets('renders floating action button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FeedPage())),
      );
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
