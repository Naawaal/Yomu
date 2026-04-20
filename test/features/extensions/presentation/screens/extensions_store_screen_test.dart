import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/core/widgets/error_state.dart';
import 'package:yomu/core/widgets/loading_shimmer.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/domain/repositories/extension_repository.dart';
import 'package:yomu/features/extensions/presentation/controllers/extensions_controllers.dart';
import 'package:yomu/features/extensions/presentation/screens/extensions_store_screen.dart';

class _FakeExtensionRepository implements ExtensionRepository {
  _FakeExtensionRepository({required this.loader});

  final Future<List<ExtensionItem>> Function() loader;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() => loader();

  @override
  Future<void> trust(String packageName) async {}

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {}
}

Widget _buildTestApp(ExtensionRepository repository) {
  return ProviderScope(
    overrides: <Override>[
      extensionRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const ExtensionsStoreScreen(),
    ),
  );
}

Widget _buildDarkTestApp(ExtensionRepository repository) {
  return ProviderScope(
    overrides: <Override>[
      extensionRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const ExtensionsStoreScreen(),
    ),
  );
}

void main() {
  const ExtensionItem testItem = ExtensionItem(
    name: 'MangaDex',
    packageName: 'eu.kanade.tachiyomi.extension.all.mangadex',
    language: 'all',
    versionName: '1.0.0',
    isInstalled: true,
    hasUpdate: false,
    isNsfw: false,
    trustStatus: ExtensionTrustStatus.trusted,
  );

  const ExtensionItem secondaryItem = ExtensionItem(
    name: 'NekoScans',
    packageName: 'eu.kanade.tachiyomi.extension.en.nekoscans',
    language: 'en',
    versionName: '2.0.0',
    isInstalled: true,
    hasUpdate: false,
    isNsfw: false,
    trustStatus: ExtensionTrustStatus.trusted,
  );

  group('ExtensionsStoreScreen', () {
    testWidgets('shows loading shimmer while repository is unresolved', (
      WidgetTester tester,
    ) async {
      final Completer<List<ExtensionItem>> completer =
          Completer<List<ExtensionItem>>();
      final repository = _FakeExtensionRepository(
        loader: () => completer.future,
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pump();

      expect(find.byType(LoadingShimmer), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state when no extensions are available', (
      WidgetTester tester,
    ) async {
      final repository = _FakeExtensionRepository(
        loader: () async => const <ExtensionItem>[],
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noExtensionsTitle), findsOneWidget);
      expect(find.text(AppStrings.noExtensionsBody), findsOneWidget);
    });

    testWidgets('shows error state when repository throws', (
      WidgetTester tester,
    ) async {
      final repository = _FakeExtensionRepository(
        loader: () => Future<List<ExtensionItem>>.error(Exception('boom')),
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });

    testWidgets('shows modern compact More Sources metadata', (
      WidgetTester tester,
    ) async {
      const ExtensionItem untrustedItem = ExtensionItem(
        name: 'MangaDex',
        packageName: 'eu.kanade.tachiyomi.extension.all.mangadex',
        language: 'all',
        versionName: '1.0.0',
        isInstalled: false,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.untrusted,
      );

      final repository = _FakeExtensionRepository(
        loader: () async => const <ExtensionItem>[untrustedItem],
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('MangaDex'), findsOneWidget);
      expect(
        find.text('eu.kanade.tachiyomi.extension.all.mangadex'),
        findsOneWidget,
      );
      expect(find.text('1.0.0'), findsOneWidget);
      expect(find.text(AppStrings.untrusted), findsOneWidget);
    });

    testWidgets('shows NSFW metadata in compact More Sources rows', (
      WidgetTester tester,
    ) async {
      const ExtensionItem nsfwItem = ExtensionItem(
        name: 'NekoScans',
        packageName: 'eu.kanade.tachiyomi.extension.en.nekoscans',
        language: 'en',
        versionName: '2.0.0',
        isInstalled: false,
        hasUpdate: false,
        isNsfw: true,
        trustStatus: ExtensionTrustStatus.untrusted,
      );

      final repository = _FakeExtensionRepository(
        loader: () async => const <ExtensionItem>[nsfwItem],
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('NekoScans'), findsOneWidget);
      expect(find.text(AppStrings.nsfw), findsOneWidget);
      expect(find.text(AppStrings.untrusted), findsOneWidget);
    });

    testWidgets('filters visible extensions by search query', (
      WidgetTester tester,
    ) async {
      final repository = _FakeExtensionRepository(
        loader: () async => const <ExtensionItem>[testItem, secondaryItem],
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'neko');
      await tester.pumpAndSettle();

      expect(find.text('MangaDex'), findsNothing);
      expect(find.text('NekoScans'), findsOneWidget);
    });

    testWidgets('filters visible extensions by selected language chip', (
      WidgetTester tester,
    ) async {
      final repository = _FakeExtensionRepository(
        loader: () async => const <ExtensionItem>[testItem, secondaryItem],
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('EN').first);
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(find.text('MangaDex'), findsNothing);
      expect(find.text('NekoScans'), findsOneWidget);
      expect(find.byIcon(Ionicons.search_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('filters visible extensions by quick filter chips', (
      WidgetTester tester,
    ) async {
      const ExtensionItem updatedItem = ExtensionItem(
        name: 'Updated Source',
        packageName: 'eu.kanade.tachiyomi.extension.en.updated',
        language: 'en',
        versionName: '3.0.0',
        isInstalled: false,
        hasUpdate: true,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
      );
      const ExtensionItem installedOnlyItem = ExtensionItem(
        name: 'Installed Source',
        packageName: 'eu.kanade.tachiyomi.extension.en.installed',
        language: 'en',
        versionName: '1.0.0',
        isInstalled: true,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
      );

      final repository = _FakeExtensionRepository(
        loader: () async => const <ExtensionItem>[
          updatedItem,
          installedOnlyItem,
        ],
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.extensionsRecentlyUpdated).first);
      await tester.pumpAndSettle();

      expect(find.text('Updated Source'), findsOneWidget);
      expect(find.text('Installed Source'), findsNothing);

      await tester.tap(find.text(AppStrings.installed).first);
      await tester.pumpAndSettle();

      expect(find.text('Installed Source'), findsOneWidget);
      expect(find.text('Updated Source'), findsNothing);
    });

    testWidgets('renders extensions screen correctly in dark theme', (
      WidgetTester tester,
    ) async {
      final repository = _FakeExtensionRepository(
        loader: () async => const <ExtensionItem>[testItem],
      );

      await tester.pumpWidget(_buildDarkTestApp(repository));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.extensionsTitle), findsWidgets);
      expect(find.text('MangaDex'), findsOneWidget);
    });

    testWidgets('search field has accessibility hint text', (
      WidgetTester tester,
    ) async {
      final repository = _FakeExtensionRepository(
        loader: () async => const <ExtensionItem>[testItem],
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.extensionsSearchHint), findsOneWidget);
    });

    testWidgets('renders explicit Installed Sources section', (
      WidgetTester tester,
    ) async {
      const ExtensionItem installedItem = ExtensionItem(
        name: 'MangaDex',
        packageName: 'eu.kanade.tachiyomi.extension.all.mangadex',
        language: 'all',
        versionName: '1.0.0',
        isInstalled: true,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
      );
      const ExtensionItem untrustedItem = ExtensionItem(
        name: 'NekoScans',
        packageName: 'eu.kanade.tachiyomi.extension.en.nekoscans',
        language: 'en',
        versionName: '2.0.0',
        isInstalled: false,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.untrusted,
      );

      final repository = _FakeExtensionRepository(
        loader: () async => const <ExtensionItem>[installedItem, untrustedItem],
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.extensionsInstalledSources), findsOneWidget);
      expect(find.text('MangaDex'), findsOneWidget);
    });
  });
}
