import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';

/// Banner displayed when an update is available for an extension.
class UpdateBanner extends StatelessWidget {
  /// Creates an update banner.
  const UpdateBanner({
    super.key,
    required this.versionName,
    required this.onUpdate,
    required this.isLoading,
  });

  /// Current extension version shown in the banner.
  final String versionName;

  /// Callback invoked when user requests update.
  final VoidCallback onUpdate;

  /// Whether update operation is running.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: InsetsTokens.card,
        child: Row(
          children: <Widget>[
            Icon(
              Icons.system_update_rounded,
              color: colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppStrings.updateAvailable,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: SpacingTokens.xxs),
                  Text(
                    '${AppStrings.versionLabel}: $versionName',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: isLoading ? null : onUpdate,
              child: const Text(AppStrings.update),
            ),
          ],
        ),
      ),
    );
  }
}
