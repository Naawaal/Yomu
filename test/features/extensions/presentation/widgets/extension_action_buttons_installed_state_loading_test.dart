import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/core/widgets/app_loader.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/presentation/widgets/extension_action_buttons.dart';

Widget _buildHarness({required ExtensionItem item, required bool isLoading}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: ExtensionActionButtons(
          item: item,
          isLoading: isLoading,
          onTrust: () {},
          onInstall: () {},
        ),
      ),
    ),
  );
}

const ExtensionItem _installedTrustedItem = ExtensionItem(
  name: 'MangaDex',
  packageName: 'pkg.installed',
  language: 'en',
  versionName: '1.0.0',
  isInstalled: true,
  hasUpdate: false,
  isNsfw: false,
  trustStatus: ExtensionTrustStatus.trusted,
);

const ExtensionItem _installedUntrustedItem = ExtensionItem(
  name: 'NekoScans',
  packageName: 'pkg.installed.untrusted',
  language: 'en',
  versionName: '1.0.0',
  isInstalled: true,
  hasUpdate: false,
  isNsfw: false,
  trustStatus: ExtensionTrustStatus.untrusted,
);

void main() {
  group('ExtensionActionButtons installed trusted no-update state', () {
    testWidgets('shows Installed chip when idle', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildHarness(item: _installedTrustedItem, isLoading: false),
      );

      expect(find.text(AppStrings.installed), findsOneWidget);
      expect(find.text(AppStrings.installing), findsNothing);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('shows Installing and loading indicator when loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildHarness(item: _installedTrustedItem, isLoading: true),
      );

      expect(find.text(AppStrings.installing), findsOneWidget);
      expect(find.text(AppStrings.installed), findsNothing);
      expect(find.byType(AppLoader), findsOneWidget);
    });

    testWidgets('shows Installed for untrusted installed items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildHarness(item: _installedUntrustedItem, isLoading: false),
      );

      expect(find.text(AppStrings.installed), findsOneWidget);
      expect(find.text(AppStrings.install), findsNothing);
      expect(find.text(AppStrings.trustAndEnable), findsNothing);
    });
  });
}
