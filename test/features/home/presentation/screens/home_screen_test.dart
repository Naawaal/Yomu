import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/home/presentation/screens/home_screen.dart';
import 'package:yomu/features/home/presentation/widgets/home_feed_card.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
        ),
      );

      await tester.pump();

      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('renders feed cards after initial fetch', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedCard), findsWidgets);
    });
  });
}
