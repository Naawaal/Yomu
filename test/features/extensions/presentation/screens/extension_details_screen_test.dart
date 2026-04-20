import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/domain/repositories/extension_repository.dart';
import 'package:yomu/features/extensions/presentation/controllers/extensions_controllers.dart';
import 'package:yomu/features/extensions/presentation/screens/extension_details_screen.dart';

class _FakeExtensionRepository implements ExtensionRepository {
  _FakeExtensionRepository({required this.items});

  final List<ExtensionItem> items;
  int trustCalls = 0;
  int installCalls = 0;
  String? trustedPackage;
  String? installedPackage;
  String? installArtifact;

  @override
  Future<List<ExtensionItem>> getAvailableExtensions() async => items;

  @override
  Future<void> trust(String packageName) async {
    trustCalls += 1;
    trustedPackage = packageName;
  }

  @override
  Future<void> install(String packageName, {String? installArtifact}) async {
    installCalls += 1;
    installedPackage = packageName;
    this.installArtifact = installArtifact;

    final int index = items.indexWhere(
      (ExtensionItem item) => item.packageName == packageName,
    );
    if (index >= 0) {
      final ExtensionItem current = items[index];
      items[index] = ExtensionItem(
        name: current.name,
        packageName: current.packageName,
        language: current.language,
        versionName: current.versionName,
        isInstalled: true,
        hasUpdate: current.hasUpdate,
        isNsfw: current.isNsfw,
        trustStatus: current.trustStatus,
        installArtifact: current.installArtifact,
        iconUrl: current.iconUrl,
      );
    }
  }
}

Widget _buildTestApp({
  required ExtensionRepository repository,
  required String packageName,
}) {
  return ProviderScope(
    overrides: <Override>[
      extensionRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: ExtensionDetailsScreen(packageName: packageName),
    ),
  );
}

void main() {
  const ExtensionItem untrustedItem = ExtensionItem(
    name: 'NekoScans',
    packageName: 'eu.kanade.tachiyomi.extension.en.nekoscans',
    language: 'en',
    versionName: '2.1.0',
    isInstalled: false,
    hasUpdate: false,
    isNsfw: false,
    trustStatus: ExtensionTrustStatus.untrusted,
    installArtifact: 'https://example.com/nekoscans.apk',
    iconUrl: 'https://example.com/nekoscans.png',
  );

  const ExtensionItem updateItem = ExtensionItem(
    name: 'MangaDex',
    packageName: 'eu.kanade.tachiyomi.extension.all.mangadex',
    language: 'all',
    versionName: '1.4.9',
    isInstalled: true,
    hasUpdate: true,
    isNsfw: false,
    trustStatus: ExtensionTrustStatus.trusted,
    installArtifact: 'https://example.com/mangadex.apk',
    iconUrl: 'https://example.com/mangadex.png',
  );

  const ExtensionItem installedUntrustedItem = ExtensionItem(
    name: 'NekoScans',
    packageName: 'eu.kanade.tachiyomi.extension.en.nekoscans.installed',
    language: 'en',
    versionName: '2.1.0',
    isInstalled: true,
    hasUpdate: false,
    isNsfw: false,
    trustStatus: ExtensionTrustStatus.untrusted,
    installArtifact: 'https://example.com/nekoscans.apk',
    iconUrl: 'https://example.com/nekoscans.png',
  );

  const ExtensionItem installableItem = ExtensionItem(
    name: 'MangaPlus',
    packageName: 'eu.kanade.tachiyomi.extension.en.mangaplus',
    language: 'en',
    versionName: '1.0.0',
    isInstalled: false,
    hasUpdate: false,
    isNsfw: false,
    trustStatus: ExtensionTrustStatus.untrusted,
    installArtifact: 'https://example.com/mangaplus.apk',
    iconUrl: 'https://example.com/mangaplus.png',
  );

  group('ExtensionDetailsScreen actions', () {
    testWidgets(
      'shows install action for untrusted extension with artifact and triggers install',
      (WidgetTester tester) async {
        final _FakeExtensionRepository repository = _FakeExtensionRepository(
          items: const <ExtensionItem>[untrustedItem],
        );

        await tester.pumpWidget(
          _buildTestApp(
            repository: repository,
            packageName: untrustedItem.packageName,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.install), findsAtLeastNWidgets(1));

        await tester.tap(find.widgetWithText(FilledButton, AppStrings.install));
        await tester.pumpAndSettle();

        expect(repository.installCalls, 1);
        expect(repository.installedPackage, untrustedItem.packageName);
        expect(repository.installArtifact, untrustedItem.installArtifact);
      },
    );

    testWidgets(
      'shows update action for trusted extension and triggers install',
      (WidgetTester tester) async {
        final _FakeExtensionRepository repository = _FakeExtensionRepository(
          items: const <ExtensionItem>[updateItem],
        );

        await tester.pumpWidget(
          _buildTestApp(
            repository: repository,
            packageName: updateItem.packageName,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.update), findsAtLeastNWidgets(1));

        await tester.tap(
          find.widgetWithText(FilledButton, AppStrings.update).first,
        );
        await tester.pumpAndSettle();

        expect(repository.installCalls, 1);
        expect(repository.installedPackage, updateItem.packageName);
        expect(repository.installArtifact, updateItem.installArtifact);
      },
    );

    testWidgets('shows installed state for untrusted installed extension', (
      WidgetTester tester,
    ) async {
      final _FakeExtensionRepository repository = _FakeExtensionRepository(
        items: const <ExtensionItem>[installedUntrustedItem],
      );

      await tester.pumpWidget(
        _buildTestApp(
          repository: repository,
          packageName: installedUntrustedItem.packageName,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.installed), findsAtLeastNWidgets(1));
      expect(find.text(AppStrings.install), findsNothing);
    });

    testWidgets('refreshes to installed state after install completes', (
      WidgetTester tester,
    ) async {
      final _FakeExtensionRepository repository = _FakeExtensionRepository(
        items: <ExtensionItem>[installableItem],
      );

      await tester.pumpWidget(
        _buildTestApp(
          repository: repository,
          packageName: installableItem.packageName,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.install), findsAtLeastNWidgets(1));

      await tester.tap(find.widgetWithText(FilledButton, AppStrings.install));
      await tester.pumpAndSettle();

      expect(repository.installCalls, 1);
      expect(find.text(AppStrings.installed), findsAtLeastNWidgets(1));
      expect(find.text(AppStrings.install), findsNothing);
    });

    testWidgets('shows not found empty state for unknown package', (
      WidgetTester tester,
    ) async {
      final _FakeExtensionRepository repository = _FakeExtensionRepository(
        items: const <ExtensionItem>[updateItem],
      );

      await tester.pumpWidget(
        _buildTestApp(repository: repository, packageName: 'missing.package'),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.extensionNotFound), findsOneWidget);
      expect(find.text(AppStrings.noExtensionsBody), findsOneWidget);
    });
  });

  group('ExtensionDetailsScreen artwork', () {
    testWidgets('shows fallback initial when iconUrl is empty', (
      WidgetTester tester,
    ) async {
      const ExtensionItem item = ExtensionItem(
        name: 'Zeta Manga',
        packageName: 'eu.kanade.tachiyomi.extension.en.zeta',
        language: 'en',
        versionName: '3.0.0',
        isInstalled: true,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.trusted,
        iconUrl: '',
      );

      final _FakeExtensionRepository repository = _FakeExtensionRepository(
        items: const <ExtensionItem>[item],
      );

      await tester.pumpWidget(
        _buildTestApp(repository: repository, packageName: item.packageName),
      );
      await tester.pumpAndSettle();

      expect(find.text('Z'), findsWidgets);
    });
  });
}
