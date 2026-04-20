import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/home/data/datasources/home_feed_remote_datasource.dart';
import 'package:yomu/features/home/data/models/home_feed_page_model.dart';
import 'package:yomu/features/home/data/models/home_feed_query_model.dart';
import 'package:yomu/features/home/presentation/screens/home_screen.dart';
import 'package:yomu/features/home/presentation/providers/home_feed_provider.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/domain/repositories/extension_repository.dart';
import 'package:yomu/features/extensions/presentation/controllers/extensions_controllers.dart';

class _FakeExtensionRepository implements ExtensionRepository {
  const _FakeExtensionRepository({this.items = const <ExtensionItem>[]});

  final List<ExtensionItem> items;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async => items;

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {}

  @override
  Future<void> trust(String packageName) async {}
}

class _EmptyHomeFeedRemoteDataSource implements HomeFeedRemoteDataSource {
  const _EmptyHomeFeedRemoteDataSource();

  @override
  Future<HomeFeedPageModel> getHomeFeedPage(HomeFeedQueryModel query) async {
    return HomeFeedPageModel(items: const [], hasMore: false);
  }

  @override
  Future<HomeFeedPageModel> refreshHomeFeed(HomeFeedQueryModel query) async {
    return HomeFeedPageModel(items: const [], hasMore: false);
  }
}

void main() {
  group('HomeScreen', () {
    testWidgets('renders app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            extensionRepositoryProvider.overrideWithValue(
              _FakeExtensionRepository(),
            ),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
        ),
      );

      await tester.pump();

      expect(find.text(AppStrings.home), findsWidgets);
    });

    testWidgets('shows tab navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            extensionRepositoryProvider.overrideWithValue(
              _FakeExtensionRepository(),
            ),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
        ),
      );

      await tester.pump();

      expect(find.text(AppStrings.feed), findsOneWidget);
      expect(find.text(AppStrings.library), findsOneWidget);
    });

    testWidgets('switches to library tab', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            extensionRepositoryProvider.overrideWithValue(
              _FakeExtensionRepository(),
            ),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.library));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.library), findsOneWidget);
    });

    testWidgets('shows no-sources empty state when no sources are installed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            extensionRepositoryProvider.overrideWithValue(
              const _FakeExtensionRepository(),
            ),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.feedEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.feedEmptyBody), findsOneWidget);
      expect(find.text(AppStrings.homeRefresh), findsNothing);
    });

    testWidgets(
      'shows no-updates empty state when sources are installed but feed is empty',
      (WidgetTester tester) async {
        const ExtensionItem installedSource = ExtensionItem(
          name: 'MangaDex',
          packageName: 'eu.kanade.tachiyomi.extension.en.mangadex',
          language: 'en',
          versionName: '1.0.0',
          isInstalled: true,
          hasUpdate: false,
          isNsfw: false,
          trustStatus: ExtensionTrustStatus.trusted,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              extensionRepositoryProvider.overrideWithValue(
                const _FakeExtensionRepository(
                  items: <ExtensionItem>[installedSource],
                ),
              ),
              homeFeedRemoteDataSourceProvider.overrideWithValue(
                const _EmptyHomeFeedRemoteDataSource(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const HomeScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(AppStrings.homeFeedEmptyTitle), findsOneWidget);
        expect(find.text(AppStrings.homeFeedEmptyBody), findsOneWidget);
        expect(find.text(AppStrings.homeRefresh), findsOneWidget);
      },
    );
  });
}
