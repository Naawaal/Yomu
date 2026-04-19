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
    hasUpdate: true,
    isNsfw: false,
    trustStatus: ExtensionTrustStatus.trusted,
    installArtifact: 'https://example.com/mangadex.apk',
    iconUrl: 'https://example.com/mangadex.png',
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
}
