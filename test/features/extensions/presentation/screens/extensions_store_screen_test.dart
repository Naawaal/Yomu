import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

void main() {
  const ExtensionItem testItem = ExtensionItem(
    name: 'MangaDex',
    packageName: 'eu.kanade.tachiyomi.extension.all.mangadex',
    language: 'all',
    versionName: '1.0.0',
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

      expect(find.byType(LoadingShimmer), findsOneWidget);
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

    testWidgets('shows extension tile when data is available', (
      WidgetTester tester,
    ) async {
      final repository = _FakeExtensionRepository(
        loader: () async => const <ExtensionItem>[testItem],
      );

      await tester.pumpWidget(_buildTestApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('MangaDex'), findsOneWidget);
      expect(find.text('ALL  1.0.0'), findsOneWidget);
    });
  });
}
