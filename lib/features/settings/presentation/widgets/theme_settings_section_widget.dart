import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../domain/entities/settings_snapshot.dart';

/// Theme configuration section for settings.
///
/// ## Card Ownership (TODO-SET-001, TODO-SET-003)
///
/// This widget renders **content only** (no card, no title).
/// The parent [SettingsScreen] wraps it in [_SettingsSectionCard] which provides:
/// - Card styling (bordered, tonal surface, AppRadius.md)
/// - Section title (AppStrings.settingsSectionTheme)
/// - Internal padding (AppSpacing.md)
///
/// This widget's responsibility:
/// - Render theme preference selector (SegmentedButton)
/// - Invoke callback on selection change
/// - Align content to parent card's internal padding
///
/// Accessibility (TODO-SET-006):
/// - SegmentedButton provides native a11y semantics
/// - Each segment has semantic label from ButtonSegment
/// - Selected state announced by platform accessibility service
///
/// Layout: Column of selectable theme options (system/light/dark) via SegmentedButton.
class ThemeSettingsSectionWidget extends StatelessWidget {
  /// Creates a theme settings section widget.
  const ThemeSettingsSectionWidget({
    super.key,
    required this.selectedPreference,
    required this.onThemeChanged,
  });

  /// Currently selected theme preference.
  final AppThemePreference selectedPreference;

  /// Invoked when the theme preference changes.
  final ValueChanged<AppThemePreference> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: AppStrings.settingsThemeSelectionSemantics,
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<AppThemePreference>(
          segments: const <ButtonSegment<AppThemePreference>>[
            ButtonSegment<AppThemePreference>(
              value: AppThemePreference.system,
              icon: Icon(Ionicons.phone_portrait_outline),
              label: Text(AppStrings.settingsThemeSystem),
            ),
            ButtonSegment<AppThemePreference>(
              value: AppThemePreference.light,
              icon: Icon(Ionicons.sunny_outline),
              label: Text(AppStrings.settingsThemeLight),
            ),
            ButtonSegment<AppThemePreference>(
              value: AppThemePreference.dark,
              icon: Icon(Ionicons.moon_outline),
              label: Text(AppStrings.settingsThemeDark),
            ),
          ],
          selected: <AppThemePreference>{selectedPreference},
          onSelectionChanged: (Set<AppThemePreference> selected) {
            if (selected.isEmpty) {
              return;
            }
            onThemeChanged(selected.first);
          },
        ),
      ),
    );
  }
}
