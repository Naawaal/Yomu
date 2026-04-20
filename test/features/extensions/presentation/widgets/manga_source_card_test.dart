import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/presentation/widgets/manga_source_card.dart';

Widget _buildCard(ExtensionItem item) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: MangaSourceCard(item: item, compact: true, onPressed: () {}),
      ),
    ),
  );
}

Widget _buildDetailedCard(ExtensionItem item) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: MangaSourceCard(item: item, onPressed: () {}),
      ),
    ),
  );
}

void main() {
  group('MangaSourceCard compact state', () {
    testWidgets('shows Installed status for installed compact item', (
      WidgetTester tester,
    ) async {
      const ExtensionItem installedItem = ExtensionItem(
        name: 'MangaDex',
        packageName: 'pkg.installed',
        language: 'en',
        versionName: '1.0.0',
        isInstalled: true,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
      );

      await tester.pumpWidget(_buildCard(installedItem));
      await tester.pumpAndSettle();

      expect(find.text('MangaDex'), findsOneWidget);
      expect(find.text(AppStrings.installed), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('shows untrusted status for uninstalled compact item', (
      WidgetTester tester,
    ) async {
      const ExtensionItem remoteItem = ExtensionItem(
        name: 'NekoScans',
        packageName: 'pkg.remote',
        language: 'en',
        versionName: '2.0.0',
        isInstalled: false,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.untrusted,
      );

      await tester.pumpWidget(_buildCard(remoteItem));
      await tester.pumpAndSettle();

      expect(find.text('NekoScans'), findsOneWidget);
      expect(find.text(AppStrings.untrusted), findsOneWidget);
    });

    testWidgets('shows update available status for updated compact item', (
      WidgetTester tester,
    ) async {
      const ExtensionItem updatedItem = ExtensionItem(
        name: 'Updated Source',
        packageName: 'pkg.updated',
        language: 'en',
        versionName: '2.0.0',
        isInstalled: false,
        hasUpdate: true,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
      );

      await tester.pumpWidget(_buildCard(updatedItem));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.updateAvailable), findsOneWidget);
      expect(find.text(AppStrings.trusted), findsNothing);
    });

    testWidgets('shows fallback initial when compact iconUrl is empty', (
      WidgetTester tester,
    ) async {
      const ExtensionItem fallbackItem = ExtensionItem(
        name: 'Nova Scan',
        packageName: 'pkg.fallback',
        language: 'en',
        versionName: '1.2.3',
        isInstalled: false,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
        iconUrl: '',
      );

      await tester.pumpWidget(_buildCard(fallbackItem));
      await tester.pumpAndSettle();

      expect(find.text('N'), findsWidgets);
    });
  });

  group('MangaSourceCard action hierarchy', () {
    testWidgets(
      'shows installed state and hides install action when installed',
      (WidgetTester tester) async {
        const ExtensionItem installedItem = ExtensionItem(
          name: 'Installed Source',
          packageName: 'pkg.installed',
          language: 'en',
          versionName: '1.0.0',
          isInstalled: true,
          hasUpdate: false,
          isNsfw: false,
          trustStatus: ExtensionTrustStatus.trusted,
        );

        await tester.pumpWidget(_buildDetailedCard(installedItem));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.installed), findsWidgets);
        expect(find.text(AppStrings.install), findsNothing);
      },
    );

    testWidgets('shows update action when installed source has update', (
      WidgetTester tester,
    ) async {
      const ExtensionItem updateItem = ExtensionItem(
        name: 'Update Source',
        packageName: 'pkg.update',
        language: 'en',
        versionName: '1.1.0',
        isInstalled: true,
        hasUpdate: true,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
      );

      await tester.pumpWidget(_buildDetailedCard(updateItem));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.update), findsOneWidget);
      expect(find.text(AppStrings.updateAvailable), findsOneWidget);
    });

    testWidgets(
      'shows Installed for untrusted installed source without update',
      (WidgetTester tester) async {
        const ExtensionItem untrustedInstalledItem = ExtensionItem(
          name: 'Untrusted Installed Source',
          packageName: 'pkg.untrusted.installed',
          language: 'en',
          versionName: '1.0.0',
          isInstalled: true,
          hasUpdate: false,
          isNsfw: false,
          trustStatus: ExtensionTrustStatus.untrusted,
        );

        await tester.pumpWidget(_buildDetailedCard(untrustedInstalledItem));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.installed), findsWidgets);
        expect(find.text(AppStrings.install), findsNothing);
        expect(find.text(AppStrings.trustAndEnable), findsNothing);
      },
    );
  });
}
