import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../domain/entities/settings_snapshot.dart';

/// Theme configuration section for settings.
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: InsetsTokens.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppStrings.settingsSectionTheme,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SpacingTokens.sm),
            SegmentedButton<AppThemePreference>(
              segments: const <ButtonSegment<AppThemePreference>>[
                ButtonSegment<AppThemePreference>(
                  value: AppThemePreference.system,
                  icon: Icon(Icons.brightness_auto_rounded),
                  label: Text(AppStrings.settingsThemeSystem),
                ),
                ButtonSegment<AppThemePreference>(
                  value: AppThemePreference.light,
                  icon: Icon(Icons.light_mode_rounded),
                  label: Text(AppStrings.settingsThemeLight),
                ),
                ButtonSegment<AppThemePreference>(
                  value: AppThemePreference.dark,
                  icon: Icon(Icons.dark_mode_rounded),
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
          ],
        ),
      ),
    );
  }
}
