import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Ionicons.color_palette_outline),
            title: const Text(AppStrings.settingsSectionTheme),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
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
        ],
      ),
    );
  }
}
