import 'package:flutter/material.dart';

import '../theme/app_colors_extension.dart';
import '../theme/tokens.dart';

/// Semantic colour variants for [AppTag].
enum AppTagVariant {
  /// Neutral/informational tag.
  neutral,

  /// Success / positive status tag.
  success,

  /// Warning / caution status tag.
  warning,

  /// Error / destructive status tag.
  error,
}

/// App-standard pill tag built on [ColorScheme] and [AppColorsExtension].
///
/// All colors derive from the theme — no hardcoded values.
///
/// ```dart
/// AppTag(label: 'Trusted', variant: AppTagVariant.success)
/// AppTag(label: 'NSFW', variant: AppTagVariant.error)
/// AppTag(label: 'EN', variant: AppTagVariant.neutral)
/// ```
class AppTag extends StatelessWidget {
  /// Creates an [AppTag].
  const AppTag({
    super.key,
    required this.label,
    this.variant = AppTagVariant.neutral,
    this.leadingIcon,
  });

  /// The text displayed inside the tag.
  final String label;

  /// Semantic colour variant.
  final AppTagVariant variant;

  /// Optional leading icon displayed before the label.
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppColorsExtension ext = Theme.of(
      context,
    ).extension<AppColorsExtension>()!;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final (Color bg, Color fg) = switch (variant) {
      AppTagVariant.neutral => (
        cs.surfaceContainerHighest,
        cs.onSurfaceVariant,
      ),
      AppTagVariant.success => (ext.successContainer, ext.onSuccessContainer),
      AppTagVariant.warning => (ext.warningContainer, ext.onWarningContainer),
      AppTagVariant.error => (cs.errorContainer, cs.onErrorContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leadingIcon != null) ...<Widget>[
            IconTheme(
              data: IconThemeData(color: fg, size: 12),
              child: leadingIcon!,
            ),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(label, style: textTheme.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}
