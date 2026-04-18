import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// App-standard dialog with M3 surface and typography contracts.
///
/// Use [AppDialog.show] instead of [showDialog] with raw [AlertDialog] in
/// feature code. This ensures consistent surface color, shape, title style,
/// and content style across all dialogs.
///
/// ```dart
/// AppDialog.show(
///   context: context,
///   title: 'Remove Source',
///   content: const Text('Are you sure you want to remove this source?'),
///   actionsBuilder: (BuildContext dialogContext) => <Widget>[
///     AppButton.outlined(
///       label: 'Cancel',
///       onPressed: () => Navigator.of(dialogContext).pop(),
///     ),
///     AppButton.destructive(label: 'Remove', onPressed: () { ... }),
///   ],
/// );
/// ```
abstract final class AppDialog {
  /// Displays a modal dialog styled to the app design system.
  ///
  /// Returns the value passed to [Navigator.pop] when the dialog closes,
  /// or `null` if dismissed.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> Function(BuildContext dialogContext) actionsBuilder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        final ColorScheme colorScheme = Theme.of(dialogContext).colorScheme;
        final TextTheme textTheme = Theme.of(dialogContext).textTheme;

        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(title),
          titleTextStyle: textTheme.headlineSmall,
          content: DefaultTextStyle(
            style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            child: content,
          ),
          actions: actionsBuilder(dialogContext),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
        );
      },
    );
  }
}
