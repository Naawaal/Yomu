import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/extensions/domain/entities/extension_item.dart';
import 'package:yomu/features/extensions/presentation/widgets/extension_tile.dart';

Widget _buildTile(ExtensionItem item) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: ExtensionTile(item: item, onPressed: () {}),
      ),
    ),
  );
}

void main() {
  group('ExtensionTile icon fallback', () {
    testWidgets('shows initials fallback when iconUrl is empty', (
      WidgetTester tester,
    ) async {
      const ExtensionItem item = ExtensionItem(
        name: 'Manga Source',
        packageName: 'pkg.empty.icon',
        language: 'en',
        versionName: '1.0.0',
        isInstalled: false,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.untrusted,
        iconUrl: '',
      );

      await tester.pumpWidget(_buildTile(item));
      await tester.pumpAndSettle();

      expect(find.text('MS'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('uses fallback artwork while network icon is unresolved', (
      WidgetTester tester,
    ) async {
      const ExtensionItem item = ExtensionItem(
        name: 'Manga Source',
        packageName: 'pkg.remote.icon',
        language: 'en',
        versionName: '1.0.0',
        isInstalled: false,
        hasUpdate: false,
        isNsfw: false,
        trustStatus: ExtensionTrustStatus.untrusted,
        iconUrl: 'https://example.invalid/icon.png',
      );

      await tester.pumpWidget(_buildTile(item));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('MS'), findsOneWidget);
    });
  });
}
