import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/core/widgets/loading_shimmer.dart';
import 'package:yomu/features/feed/domain/entities/feed_filter.dart';
import 'package:yomu/features/feed/domain/entities/feed_item.dart';
import 'package:yomu/features/feed/domain/repositories/feed_repository.dart';
import 'package:yomu/features/feed/presentation/controllers/feed_controller.dart';
import 'package:yomu/features/main/presentation/screens/home_screen.dart';

// ---------------------------------------------------------------------------
// Fake repository helpers
// ---------------------------------------------------------------------------

/// Fake [FeedRepository] backed by a [Completer] — useful for loading state.
class _BlockingFeedRepository implements FeedRepository {
  _BlockingFeedRepository(this._completer);

  final Completer<List<FeedItem>> _completer;

  @override
  Future<List<FeedItem>> getFeedItems({
    required FeedFilter filter,
    int page = 1,
    int pageSize = 20,
  }) => _completer.future;

  @override
  Future<List<FeedItem>> refreshFeed({
    required FeedFilter filter,
    int pageSize = 20,
  }) => _completer.future;
}

/// Fake [FeedRepository] that either returns items or throws.
class _SyncFeedRepository implements FeedRepository {
  const _SyncFeedRepository({required this.items, this.throwError});

  final List<FeedItem> items;
  final Object? throwError;

  @override
  Future<List<FeedItem>> getFeedItems({
    required FeedFilter filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (throwError != null) throw throwError!;
    return items;
  }

  @override
  Future<List<FeedItem>> refreshFeed({
    required FeedFilter filter,
    int pageSize = 20,
  }) async {
    if (throwError != null) throw throwError!;
    return items;
  }
}

// ---------------------------------------------------------------------------
// Widget builder
// ---------------------------------------------------------------------------

Widget _buildApp(FeedRepository repository) {
  return ProviderScope(
    overrides: <Override>[feedRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const HomeScreen(),
    ),
  );
}

Widget _buildDarkApp(FeedRepository repository) {
  return ProviderScope(
    overrides: <Override>[feedRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Test feed items
// ---------------------------------------------------------------------------

final DateTime _now = DateTime(2026, 4, 17);

// DateTime can't be const — use a factory helper.
FeedItem _testFeedItem(String id, String title) => FeedItem(
  id: id,
  sourceId: 'test.source.$id',
  title: title,
  subtitle: 'Chapter 1',
  imageUrl: '',
  metadata: 'TestSource • ${_now.month}/${_now.day}',
  isBookmarked: false,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HomeScreen', () {
    // ───────────────────────────────────────────────────────────────────────
    // 1. Loading state
    // ───────────────────────────────────────────────────────────────────────

    testWidgets('shows LoadingShimmer while repository is unresolved', (
      WidgetTester tester,
    ) async {
      final Completer<List<FeedItem>> completer = Completer<List<FeedItem>>();

      await tester.pumpWidget(_buildApp(_BlockingFeedRepository(completer)));
      // Single pump — controller is loading, shimmer should appear.
      await tester.pump();

      expect(find.byType(LoadingShimmer), findsOneWidget);
    });

    // ───────────────────────────────────────────────────────────────────────
    // 2. Error state
    // ───────────────────────────────────────────────────────────────────────

    testWidgets('shows error heading when repository throws', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const _SyncFeedRepository(
            items: <FeedItem>[],
            throwError: 'fetch failed',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.feedLoadFailed), findsOneWidget);
    });

    testWidgets('shows retry button in error state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const _SyncFeedRepository(
            items: <FeedItem>[],
            throwError: 'fetch failed',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.retry), findsOneWidget);
    });

    // ───────────────────────────────────────────────────────────────────────
    // 3. Empty state
    // ───────────────────────────────────────────────────────────────────────

    testWidgets('shows empty-state heading when feed has no items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const _SyncFeedRepository(items: <FeedItem>[])),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.feedEmptyTitle), findsOneWidget);
    });

    testWidgets('shows empty-state body copy when feed has no items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const _SyncFeedRepository(items: <FeedItem>[])),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.feedEmptyBody), findsOneWidget);
    });

    testWidgets('shows Browse Extensions action in empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const _SyncFeedRepository(items: <FeedItem>[])),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.feedBrowseExtensions), findsOneWidget);
    });

    // ───────────────────────────────────────────────────────────────────────
    // 4. Data state
    // ───────────────────────────────────────────────────────────────────────

    testWidgets('renders item titles when feed returns data', (
      WidgetTester tester,
    ) async {
      final List<FeedItem> items = <FeedItem>[
        _testFeedItem('id-01', 'Kaiju No. 8'),
        _testFeedItem('id-02', 'Blue Lock'),
      ];

      await tester.pumpWidget(_buildApp(_SyncFeedRepository(items: items)));
      await tester.pumpAndSettle();

      expect(find.text('Kaiju No. 8'), findsOneWidget);
      expect(find.text('Blue Lock'), findsOneWidget);
    });

    testWidgets(
      'does not show loading shimmer or empty state when data loads',
      (WidgetTester tester) async {
        final List<FeedItem> items = <FeedItem>[
          _testFeedItem('id-01', 'Frieren'),
        ];

        await tester.pumpWidget(_buildApp(_SyncFeedRepository(items: items)));
        await tester.pumpAndSettle();

        expect(find.byType(LoadingShimmer), findsNothing);
        expect(find.text(AppStrings.feedEmptyTitle), findsNothing);
        expect(find.text(AppStrings.feedLoadFailed), findsNothing);
      },
    );

    // ───────────────────────────────────────────────────────────────────────
    // 5. App bar
    // ───────────────────────────────────────────────────────────────────────

    testWidgets('renders Home app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(const _SyncFeedRepository(items: <FeedItem>[])),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.home), findsWidgets);
    });

    testWidgets('renders home screen correctly in dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildDarkApp(const _SyncFeedRepository(items: <FeedItem>[])),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.home), findsWidgets);
      expect(find.text(AppStrings.feedBrowseExtensions), findsOneWidget);
    });

    testWidgets('exposes refresh semantics for accessibility', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const _SyncFeedRepository(items: <FeedItem>[])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
