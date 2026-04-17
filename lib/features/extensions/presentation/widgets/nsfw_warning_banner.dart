import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_theme_extension.dart';
import '../../../../../core/theme/tokens.dart';

/// Warning banner displayed for NSFW extensions.
class NsfwWarningBanner extends StatelessWidget {
  /// Creates an NSFW warning banner.
  const NsfwWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeExtension appTheme =
        Theme.of(context).extension<AppThemeExtension>()!;

    return Card(
      color: appTheme.warningContainerColor,
      child: Padding(
        padding: InsetsTokens.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.warning_amber_rounded,
              color: appTheme.warningColor,
            ),
            const SizedBox(width: SpacingTokens.sm),
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
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    AppStrings.nsfwBody,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
