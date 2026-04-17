import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';

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

    return AppCard(
      child: Row(
        children: <Widget>[
          Icon(
            Ionicons.download_outline,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.updateAvailable,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${AppStrings.versionLabel}: $versionName',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          AppButton(
            onPressed: isLoading ? null : onUpdate,
            label: AppStrings.update,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}
