import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../theme/tokens.dart';
import 'app_button.dart';

/// Standardized empty-state surface.
class EmptyState extends StatelessWidget {
  /// Creates an [EmptyState].
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.icon = Ionicons.file_tray_outline,
  });

  /// Empty-state title.
  final String title;

  /// Empty-state description.
  final String description;

  /// Optional action button label.
  final String? actionLabel;

  /// Optional action callback.
  final VoidCallback? onAction;

  /// Empty-state icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
