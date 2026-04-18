import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// App-standard bottom sheet with M3 surface and drag-handle contract.
///
/// Use [AppBottomSheet.show] instead of [showModalBottomSheet] in feature code.
/// This enforces the design-system surface color, top radius, drag handle, and
/// safe-area handling consistently across all sheets.
///
/// ```dart
/// AppBottomSheet.show(
///   context: context,
///   title: 'Sort by',
///   child: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [ ... ],
///   ),
/// );
/// ```
abstract final class AppBottomSheet {
  /// Displays a modal bottom sheet styled to the app design system.
  ///
  /// [child] is the sheet body content.
  /// [title] renders an optional header above [child].
  ///
  /// Returns the value passed to [Navigator.pop] when the sheet closes,
  /// or `null` if dismissed.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final ColorScheme colorScheme = Theme.of(sheetContext).colorScheme;
        final TextTheme textTheme = Theme.of(sheetContext).textTheme;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (title != null) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      title,
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}
