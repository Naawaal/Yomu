import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/home/presentation/screens/home_screen.dart';
import 'package:yomu/features/home/presentation/widgets/home_continue_reading_hero.dart';
import 'package:yomu/features/home/presentation/widgets/home_feed_card.dart';
import 'package:yomu/features/home/presentation/widgets/home_library_progress_shelf.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
        ),
      );

      await tester.pump();

      expect(find.text(AppStrings.home), findsWidgets);
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

    testWidgets('shows feed tab modules by default on first render', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.feed), findsOneWidget);
      expect(find.byType(HomeContinueReadingHero), findsOneWidget);
      expect(find.byType(HomeFeedCard), findsWidgets);
      expect(find.byType(HomeLibraryProgressShelf), findsNothing);
    });

    testWidgets('switches to library tab and shows progress shelf module', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 1800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.library));
      await tester.pumpAndSettle();

      expect(find.byType(HomeLibraryProgressShelf), findsOneWidget);
      expect(find.byType(HomeContinueReadingHero), findsNothing);
    });
  });
}
