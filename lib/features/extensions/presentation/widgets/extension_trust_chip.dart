import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';

/// Trust status chip for an extension.
class ExtensionTrustChip extends StatelessWidget {
  /// Creates a trust status chip.
  const ExtensionTrustChip({super.key, required this.trusted});

  /// Whether the extension is trusted.
  final bool trusted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color background = trusted
        ? colorScheme.primaryContainer
        : colorScheme.errorContainer;
    final Color foreground = trusted
        ? colorScheme.onPrimaryContainer
        : colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SpacingTokens.xs),
      ),
      child: Text(
        trusted ? AppStrings.trusted : AppStrings.untrusted,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}
