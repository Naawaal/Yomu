import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_theme_extension.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';

/// Warning banner displayed for NSFW extensions.
class NsfwWarningBanner extends StatelessWidget {
  /// Creates an NSFW warning banner.
  const NsfwWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeExtension appTheme = Theme.of(
      context,
    ).extension<AppThemeExtension>()!;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Ionicons.warning_outline, color: appTheme.warningColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.nsfwContent,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: appTheme.warningColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.nsfwBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
