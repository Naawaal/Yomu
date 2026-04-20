import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yomu/core/constants/app_strings.dart';
import 'package:yomu/core/theme/app_theme.dart';
import 'package:yomu/features/settings/domain/entities/settings_snapshot.dart';
import 'package:yomu/features/settings/presentation/widgets/theme_settings_section_widget.dart';

Widget _buildWidget(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  testWidgets('renders all theme options and invokes selection callback', (
    WidgetTester tester,
  ) async {
    AppThemePreference? selectedPreference;

    await tester.pumpWidget(
      _buildWidget(
        ThemeSettingsSectionWidget(
          selectedPreference: AppThemePreference.system,
          onThemeChanged: (AppThemePreference preference) {
            selectedPreference = preference;
          },
        ),
      ),
    );

    expect(find.text(AppStrings.settingsThemeSystem), findsOneWidget);
    expect(find.text(AppStrings.settingsThemeLight), findsOneWidget);
    expect(find.text(AppStrings.settingsThemeDark), findsOneWidget);

    await tester.tap(find.text(AppStrings.settingsThemeDark));
    await tester.pumpAndSettle();

    expect(selectedPreference, AppThemePreference.dark);
  });
}
