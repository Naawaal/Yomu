import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/settings/domain/entities/settings_snapshot.dart';
import 'package:yomu/features/settings/presentation/widgets/backup_settings_section_widget.dart';

Widget _buildWidget(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  testWidgets('renders backup timestamps and triggers export/import actions', (
    WidgetTester tester,
  ) async {
    int exportCalls = 0;
    int importCalls = 0;

    await tester.pumpWidget(
      _buildWidget(
        BackupSettingsSectionWidget(
          backup: BackupSnapshot(
            version: 1,
            lastExportedAt: DateTime.utc(2026, 4, 20, 10, 15, 0),
            lastImportedAt: DateTime.utc(2026, 4, 19, 8, 30, 0),
          ),
          onExportBackup: () {
            exportCalls += 1;
          },
          onImportBackup: () {
            importCalls += 1;
          },
        ),
      ),
    );

    expect(find.text(AppStrings.settingsBackupExport), findsOneWidget);
    expect(find.text(AppStrings.settingsBackupImport), findsOneWidget);
    expect(
      find.text('Last export: 2026-04-20T10:15:00.000Z'),
      findsOneWidget,
    );
    expect(
      find.text('Last import: 2026-04-19T08:30:00.000Z'),
      findsOneWidget,
    );

    await tester.tap(find.byType(ListTile).at(0));
    await tester.pump();
    await tester.tap(find.byType(ListTile).at(1));
    await tester.pump();

    expect(exportCalls, 1);
    expect(importCalls, 1);
  });
}
